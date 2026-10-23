import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/datasources/auth_remote_datasource.dart';

class TrackingService extends ChangeNotifier {
  TrackingService._();
  static final TrackingService instance = TrackingService._();
  bool _initialized = false;
  bool _autoScrobble = true;
  bool _isSyncing = false;
  int _fetchRevision = 0;
  List<Map<String, dynamic>> _connections = [];
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _conflicts = [];
  final Set<String> _writing = {};
  String? lastError;
  final _session = AccountSession.instance;

  Map<String, dynamic> _connection(String provider) => _connections.firstWhere((c) => c['provider'] == provider, orElse: () => {});
  bool get isAniListConnected => _connection('anilist')['connected'] == true;
  bool get isMalConnected => _connection('mal')['connected'] == true;
  String? get aniListUsername => _connection('anilist')['username'] as String?;
  String? get malUsername => _connection('mal')['username'] as String?;
  String? get aniListStatus => _connection('anilist')['status'] as String?;
  String? get malStatus => _connection('mal')['status'] as String?;
  String? get aniListError => _connection('anilist')['error'] as String?;
  String? get malError => _connection('mal')['error'] as String?;
  DateTime? get aniListLastSyncedAt => DateTime.tryParse(_connection('anilist')['lastSyncedAt']?.toString() ?? '');
  DateTime? get malLastSyncedAt => DateTime.tryParse(_connection('mal')['lastSyncedAt']?.toString() ?? '');
  Map<String, dynamic>? get aniListUser => isAniListConnected ? {'name': aniListUsername ?? '', 'status': aniListStatus, 'lastSyncedAt': aniListLastSyncedAt?.toIso8601String()} : null;
  Map<String, dynamic>? get malUser => isMalConnected ? {'name': malUsername ?? '', 'status': malStatus, 'lastSyncedAt': malLastSyncedAt?.toIso8601String()} : null;
  bool get autoScrobble => _autoScrobble;
  bool get isSyncing => _isSyncing;
  List<Map<String, dynamic>> get entries => List.unmodifiable(_entries.map(Map<String, dynamic>.unmodifiable));
  List<Map<String, dynamic>> get conflicts => List.unmodifiable(_conflicts.map(Map<String, dynamic>.unmodifiable));
  bool _current(int generation) => _session.isCurrent(generation) && _session.userId != null;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final box = await Hive.openBox('tracking_integrations');
    _autoScrobble = box.get('auto_scrobble', defaultValue: true) == true;
    await box.delete('cached_integrations_v2');
    _session.addListener(_sessionChanged);
    _sessionChanged();
  }

  void _sessionChanged() {
    _fetchRevision++;
    _connections = [];
    _entries = [];
    _conflicts = [];
    _writing.clear();
    _isSyncing = false;
    lastError = null;
    notifyListeners();
    if (_current(_session.generation)) unawaited(fetchIntegrations());
  }

  Future<void> setAutoScrobble(bool enabled) async {
    _autoScrobble = enabled;
    notifyListeners();
    final box = await Hive.openBox('tracking_integrations');
    await box.put('auto_scrobble', enabled);
  }

  Future<bool> fetchIntegrations() async {
    final generation = _session.generation;
    if (!_current(generation)) return false;
    final revision = ++_fetchRevision;
    try {
      final response = await GetIt.I<DioClient>().get('/api/integrations');
      if (!_current(generation) || revision != _fetchRevision) return false;
      final data = response.data;
      if (data is! Map || data['success'] == false || data['entries'] is! List || data['connections'] is! List) throw StateError('Invalid integrations response');
      _connections = (data['connections'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _entries = (data['entries'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _conflicts = (data['conflicts'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      lastError = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (_current(generation) && revision == _fetchRevision) {
        lastError = 'Takip bilgileri yenilenemedi.';
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> linkProvider({required String provider, required Future<void> Function(String url) onOpenUrl}) async {
    final generation = _session.generation;
    if (!_current(generation)) return false;
    try {
      final auth = GetIt.I<AuthRemoteDataSource>();
      final session = await auth.startOAuth(provider: provider, intent: 'link');
      if (!_current(generation)) return false;
      await onOpenUrl(session.authorizationUrl);
      if (!_current(generation)) return false;
      final success = await auth.pollOAuthLink(transactionId: session.transactionId, verifier: session.verifier);
      if (!_current(generation) || !success) return false;
      await triggerSync();
      return _current(generation);
    } catch (_) {
      return false;
    }
  }

  Future<bool> disconnectProvider({required String provider, String? password}) async {
    final generation = _session.generation;
    if (!_current(generation)) return false;
    try {
      await GetIt.I<DioClient>().delete('/api/integrations/$provider', data: password != null && password.isNotEmpty ? {'password': password} : {});
      if (!_current(generation)) return false;
      return await fetchIntegrations();
    } catch (_) {
      return false;
    }
  }
  Future<bool> disconnectAniList() => disconnectProvider(provider: 'anilist');
  Future<bool> disconnectMal() => disconnectProvider(provider: 'mal');

  Future<void> triggerSync() async {
    final generation = _session.generation;
    if (!_current(generation) || _isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await GetIt.I<DioClient>().post('/api/integrations/sync');
      if (_current(generation)) await fetchIntegrations();
    } catch (_) {
      if (_current(generation)) lastError = 'Eşitleme başlatılamadı.';
    } finally {
      if (_current(generation)) {
        _isSyncing = false;
        notifyListeners();
      }
    }
  }

  Future<bool> resolveConflict({required String entryId, required String provider, required int version, required int entryVersion, required String choice, bool confirmDeletion = false}) async {
    final generation = _session.generation;
    if (!_current(generation)) return false;
    try {
      await GetIt.I<DioClient>().post('/api/tracking/conflicts/resolve', data: {
        'entryId': entryId, 'provider': provider, 'version': version,
        'entryVersion': entryVersion, 'choice': choice,
        if (confirmDeletion) 'confirmDeletion': true,
      });
      if (!_current(generation)) return false;
      return await fetchIntegrations();
    } catch (_) {
      if (_current(generation)) await fetchIntegrations();
      return false;
    }
  }

  Future<bool> scrobbleEpisode({required String animeTitle, String? animeId, required int episode, bool isCompleted = false, int? totalEpisodes}) async {
    if (!_autoScrobble || (!isAniListConnected && !isMalConnected) || animeId == null || animeId.isEmpty || episode < 1) return false;
    return _writeProgress(sourceId: animeId, title: animeTitle, episode: episode, totalEpisodes: totalEpisodes);
  }

  Future<bool> updateProgress({required String sourceId, required String title, required int completedEpisodes, int? totalEpisodes}) => _writeProgress(sourceId: sourceId, title: title, episode: completedEpisodes, totalEpisodes: totalEpisodes);

  Future<bool> _writeProgress({required String sourceId, required String title, required int episode, int? totalEpisodes}) async {
    final generation = _session.generation;
    if (!_current(generation) || sourceId.isEmpty || episode < 0 || !_writing.add(sourceId)) return false;
    try {
      if (!await fetchIntegrations() || !_current(generation)) return false;
      final matches = _entries.where((entry) => entry['sourceId'] == sourceId).toList();
      if (matches.length > 1) throw StateError('Ambiguous source mapping');
      final match = matches.isEmpty ? null : matches.single;
      final dio = GetIt.I<DioClient>();
      final Response response;
      if (match != null) {
        if (match['id'] is! String || match['version'] is! int) throw StateError('Missing entry version');
        response = await dio.post('/api/tracking/progress', data: {'entryId': match['id'], 'version': match['version'], 'completedEpisodes': episode});
      } else {
        response = await dio.patch('/api/tracking/entries', data: {
          'sourceId': sourceId, 'title': title,
          ...?((totalEpisodes != null) ? {'totalEpisodes': totalEpisodes} : null),
          'confirmMapping': true,
          'value': {'progress': episode, 'status': totalEpisodes != null && episode >= totalEpisodes ? 'completed' : 'watching'},
        });
      }
      if (!_current(generation)) return false;
      final data = response.data;
      if (data is! Map || data['success'] == false) throw StateError('Invalid tracking response');
      final raw = data['entry'];
      if (raw is! Map || raw['id'] is! String || raw['version'] is! int || raw['sourceId'] != sourceId) throw StateError('Missing canonical entry');
      _fetchRevision++;
      _entries.removeWhere((entry) => entry['id'] == raw['id'] || entry['sourceId'] == sourceId);
      _entries.add(Map<String, dynamic>.from(raw));
      lastError = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      if (_current(generation)) {
        if (e.response?.statusCode == 409) await fetchIntegrations();
        if (_current(generation)) {
          lastError = e.response?.statusCode == 409 ? 'İlerleme başka bir cihazda değişti. Yeniden deneyin.' : 'İlerleme kaydedilemedi.';
          notifyListeners();
        }
      }
      return false;
    } catch (_) {
      if (_current(generation)) {
        lastError = 'İlerleme kaydedilemedi.';
        notifyListeners();
      }
      return false;
    } finally {
      if (_current(generation)) _writing.remove(sourceId);
    }
  }
}
