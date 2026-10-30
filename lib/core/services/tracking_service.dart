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
  final Set<String> _busyEntries = {};
  bool _entriesLoaded = false;
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
  bool get entriesLoaded => _entriesLoaded;
  bool isEntryBusy(String id) => _busyEntries.contains(id);
  bool _current(int generation) => _session.isCurrent(generation) && _session.userId != null;

  /// Ordered tracking status keys used by the "Kütüphanem" screen and menus.
  static const List<String> statusOrder = ['watching', 'plan_to_watch', 'completed', 'dropped', 'on_hold'];

  /// Human readable labels for tracking statuses (matches the web app copy).
  static const Map<String, String> statusLabels = {
    'watching': 'Devam Ediyor',
    'plan_to_watch': 'Planlandı',
    'completed': 'Bitirildi',
    'dropped': 'Bırakıldı',
    'on_hold': 'Beklemede',
  };

  static Object? _valueOf(Map<String, dynamic> entry, String key) {
    final value = entry['value'];
    return value is Map ? value[key] : null;
  }

  static String entryStatus(Map<String, dynamic> entry) => _valueOf(entry, 'status')?.toString() ?? '';

  static int entryProgress(Map<String, dynamic> entry) {
    final progress = _valueOf(entry, 'progress');
    if (progress is num) return progress.toInt();
    return int.tryParse(progress?.toString() ?? '') ?? 0;
  }

  static int entryScore(Map<String, dynamic> entry) {
    final score = _valueOf(entry, 'score');
    if (score is num) return score.toInt();
    return int.tryParse(score?.toString() ?? '') ?? 0;
  }

  static String? entryPoster(Map<String, dynamic> entry) {
    final poster = _valueOf(entry, 'poster')?.toString();
    return poster == null || poster.isEmpty ? null : poster;
  }

  static int? entryTotalEpisodes(Map<String, dynamic> entry) {
    final total = entry['totalEpisodes'] ?? _valueOf(entry, 'totalEpisodes');
    if (total is num) return total.toInt();
    return int.tryParse(total?.toString() ?? '');
  }

  /// Finds the tracking entry for an anime by exact source id, then by title.
  Map<String, dynamic>? entryFor({String? sourceId, required String title}) {
    if (sourceId != null && sourceId.isNotEmpty) {
      for (final entry in _entries) {
        if (entry['sourceId']?.toString() == sourceId) {
          return Map<String, dynamic>.unmodifiable(entry);
        }
      }
    }
    final normalizedTitle = title.trim().toLowerCase();
    if (normalizedTitle.isEmpty) return null;
    for (final entry in _entries) {
      if (entry['title']?.toString().trim().toLowerCase() == normalizedTitle) {
        return Map<String, dynamic>.unmodifiable(entry);
      }
    }
    return null;
  }

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
    _busyEntries.clear();
    _entriesLoaded = false;
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

  Future<bool> refreshEntries() async {
    final generation = _session.generation;
    if (!_current(generation)) return false;
    final revision = ++_fetchRevision;
    try {
      final response = await GetIt.I<DioClient>().get('/api/tracking/entries');
      if (!_current(generation) || revision != _fetchRevision) return false;
      final data = response.data;
      if (data is! Map || data['entries'] is! List) throw StateError('Invalid tracking entries response');
      _entries = (data['entries'] as List).whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
      _entriesLoaded = true;
      lastError = null;
      notifyListeners();
      return true;
    } catch (_) {
      if (_current(generation) && revision == _fetchRevision) {
        lastError = 'Kütüphane yüklenemedi. Eşitle ile tekrar deneyin.';
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

  /// Adds an anime to the user's library (or updates the existing entry).
  Future<bool> addEntry({
    required String sourceId,
    required String title,
    String? poster,
    int? totalEpisodes,
    String status = 'plan_to_watch',
  }) async {
    final generation = _session.generation;
    if (!_current(generation) || sourceId.isEmpty || title.trim().isEmpty) return false;
    if (!_busyEntries.add(sourceId)) return false;
    notifyListeners();
    return _mutateEntry(
      busyKey: sourceId,
      generation: generation,
      fallback: 'Kütüphaneye eklenemedi.',
      action: (dio) => dio.patch('/api/tracking/entries', data: {
        'sourceId': sourceId,
        'title': title,
        'totalEpisodes': ?totalEpisodes,
        'confirmMapping': true,
        'value': {
          'status': status,
          if (poster != null && poster.isNotEmpty) 'poster': poster,
        },
      }),
    );
  }

  /// Changes the status value of an existing tracking entry.
  Future<bool> setEntryStatus(Map<String, dynamic> entry, String status) async {
    final generation = _session.generation;
    final id = entry['id'];
    if (!_current(generation) || id is! String || entry['version'] is! int) return false;
    if (!_busyEntries.add(id)) return false;
    notifyListeners();
    return _mutateEntry(
      busyKey: id,
      generation: generation,
      fallback: 'Durum güncellenemedi.',
      action: (dio) => dio.patch('/api/tracking/entries', data: {
        'id': id,
        'version': entry['version'],
        if (entry['sourceId'] != null) 'sourceId': entry['sourceId'],
        if (entry['title'] != null) 'title': entry['title'],
        'confirmMapping': true,
        'value': {'status': status},
      }),
    );
  }

  /// Updates the completed episode count of an existing tracking entry.
  Future<bool> setEntryProgress(Map<String, dynamic> entry, int completedEpisodes) async {
    final generation = _session.generation;
    final id = entry['id'];
    if (!_current(generation) || id is! String || entry['version'] is! int || completedEpisodes < 0) return false;
    if (!_busyEntries.add(id)) return false;
    notifyListeners();
    return _mutateEntry(
      busyKey: id,
      generation: generation,
      fallback: 'İlerleme kaydedilemedi.',
      action: (dio) => dio.post('/api/tracking/progress', data: {
        'entryId': id,
        'version': entry['version'],
        'completedEpisodes': completedEpisodes,
      }),
    );
  }

  /// Removes an entry from the user's library.
  Future<bool> removeEntry(Map<String, dynamic> entry) async {
    final generation = _session.generation;
    final id = entry['id'];
    if (!_current(generation) || id is! String) return false;
    if (!_busyEntries.add(id)) return false;
    notifyListeners();
    return _mutateEntry(
      busyKey: id,
      generation: generation,
      fallback: 'Kütüphaneden kaldırılamadı.',
      action: (dio) => dio.delete('/api/tracking/entries', data: {
        'id': id,
        if (entry['version'] is int) 'version': entry['version'],
      }),
    );
  }

  Future<bool> _mutateEntry({
    required String busyKey,
    required int generation,
    required String fallback,
    required Future<void> Function(DioClient dio) action,
  }) async {
    try {
      await action(GetIt.I<DioClient>());
      if (!_current(generation)) return false;
      await refreshEntries();
      return true;
    } on DioException catch (e) {
      if (!_current(generation)) return false;
      if (e.response?.statusCode == 409) {
        await refreshEntries();
        if (_current(generation)) {
          lastError = 'İlerleme başka bir cihazda değişti. Yeniden deneyin.';
          notifyListeners();
        }
      } else {
        lastError = fallback;
        notifyListeners();
      }
      return false;
    } catch (_) {
      if (_current(generation)) {
        lastError = fallback;
        notifyListeners();
      }
      return false;
    } finally {
      _busyEntries.remove(busyKey);
      if (_current(generation)) notifyListeners();
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
