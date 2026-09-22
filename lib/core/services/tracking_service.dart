import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/datasources/auth_remote_datasource.dart';

class TrackingService extends ChangeNotifier {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  static const String _boxName = 'tracking_integrations';
  static const String _autoScrobbleKey = 'auto_scrobble';
  static const String _cachedIntegrationsKey = 'cached_integrations_v2';

  bool _initialized = false;
  bool _autoScrobble = true;
  bool _isSyncing = false;

  bool _isAniListConnected = false;
  String? _aniListUsername;
  String? _aniListStatus;
  DateTime? _aniListLastSyncedAt;
  String? _aniListError;

  bool _isMalConnected = false;
  String? _malUsername;
  String? _malStatus;
  DateTime? _malLastSyncedAt;
  String? _malError;

  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _conflicts = [];

  bool get isAniListConnected => _isAniListConnected;
  bool get isMalConnected => _isMalConnected;
  String? get aniListUsername => _aniListUsername;
  String? get malUsername => _malUsername;
  String? get aniListStatus => _aniListStatus;
  String? get malStatus => _malStatus;
  DateTime? get aniListLastSyncedAt => _aniListLastSyncedAt;
  DateTime? get malLastSyncedAt => _malLastSyncedAt;
  String? get aniListError => _aniListError;
  String? get malError => _malError;

  Map<String, dynamic>? get aniListUser => _isAniListConnected
      ? {
          'name': _aniListUsername ?? '',
          'status': _aniListStatus,
          'lastSyncedAt': _aniListLastSyncedAt?.toIso8601String(),
        }
      : null;

  Map<String, dynamic>? get malUser => _isMalConnected
      ? {
          'name': _malUsername ?? '',
          'status': _malStatus,
          'lastSyncedAt': _malLastSyncedAt?.toIso8601String(),
        }
      : null;

  bool get autoScrobble => _autoScrobble;
  bool get isSyncing => _isSyncing;
  List<Map<String, dynamic>> get entries => _entries;
  List<Map<String, dynamic>> get conflicts => _conflicts;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final box = await Hive.openBox(_boxName);
      _autoScrobble = (box.get(_autoScrobbleKey) as bool?) ?? true;
      final cachedRaw = box.get(_cachedIntegrationsKey);
      if (cachedRaw is String) {
        try {
          final data = jsonDecode(cachedRaw) as Map<String, dynamic>;
          _applyIntegrationsData(data);
        } catch (_) {}
      }
    } catch (_) {}

    _initialized = true;
    fetchIntegrations();
  }

  Future<void> setAutoScrobble(bool enabled) async {
    _autoScrobble = enabled;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_autoScrobbleKey, enabled);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchIntegrations() async {
    try {
      final dio = GetIt.I<DioClient>();
      final response = await dio.get('${ApiConstants.caliumBackendUrl}/api/integrations');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _applyIntegrationsData(data);
        try {
          final box = await Hive.openBox(_boxName);
          await box.put(_cachedIntegrationsKey, jsonEncode(data));
        } catch (_) {}
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching integrations: $e');
    }
  }

  void _applyIntegrationsData(Map<String, dynamic> data) {
    final connections = (data['connections'] as List?)?.cast<dynamic>() ?? [];
    for (final raw in connections) {
      if (raw is! Map) continue;
      final conn = Map<String, dynamic>.from(raw);
      final provider = conn['provider'] as String?;
      final connected = conn['connected'] == true;
      final username = conn['username'] as String?;
      final status = conn['status'] as String?;
      final error = conn['error'] as String?;
      DateTime? lastSynced;
      if (conn['lastSyncedAt'] != null) {
        try {
          lastSynced = DateTime.parse(conn['lastSyncedAt'].toString());
        } catch (_) {}
      }

      if (provider == 'anilist') {
        _isAniListConnected = connected;
        _aniListUsername = username;
        _aniListStatus = status;
        _aniListError = error;
        _aniListLastSyncedAt = lastSynced;
      } else if (provider == 'mal') {
        _isMalConnected = connected;
        _malUsername = username;
        _malStatus = status;
        _malError = error;
        _malLastSyncedAt = lastSynced;
      }
    }

    if (data['entries'] is List) {
      _entries = (data['entries'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data['conflicts'] is List) {
      _conflicts = (data['conflicts'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }

  Future<bool> linkProvider({
    required String provider,
    required Future<void> Function(String url) onOpenUrl,
  }) async {
    try {
      final authDataSource = GetIt.I<AuthRemoteDataSource>();
      final session = await authDataSource.startOAuth(
        provider: provider,
        intent: 'link',
      );
      await onOpenUrl(session.authorizationUrl);
      final success = await authDataSource.pollOAuthLink(
        transactionId: session.transactionId,
        verifier: session.verifier,
      );
      if (success) {
        await triggerSync();
        await fetchIntegrations();
      }
      return success;
    } catch (e) {
      debugPrint('Error linking provider $provider: $e');
      return false;
    }
  }

  Future<bool> disconnectProvider({
    required String provider,
    String? password,
  }) async {
    try {
      final dio = GetIt.I<DioClient>();
      await dio.delete(
        '${ApiConstants.caliumBackendUrl}/api/integrations/$provider',
        data: password != null && password.isNotEmpty ? {'password': password} : {},
      );
      await fetchIntegrations();
      return true;
    } catch (e) {
      debugPrint('Error disconnecting provider $provider: $e');
      return false;
    }
  }

  Future<bool> disconnectAniList() => disconnectProvider(provider: 'anilist');
  Future<bool> disconnectMal() => disconnectProvider(provider: 'mal');

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      final dio = GetIt.I<DioClient>();
      await dio.post('${ApiConstants.caliumBackendUrl}/api/integrations/sync');
      await Future.delayed(const Duration(seconds: 1));
      await fetchIntegrations();
    } catch (e) {
      debugPrint('Error triggering sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> resolveConflict({
    required String entryId,
    required String provider,
    required int version,
    required int entryVersion,
    required String choice,
    bool confirmDeletion = false,
  }) async {
    try {
      final dio = GetIt.I<DioClient>();
      await dio.post(
        '${ApiConstants.caliumBackendUrl}/api/tracking/conflicts/resolve',
        data: {
          'entryId': entryId,
          'provider': provider,
          'version': version,
          'entryVersion': entryVersion,
          'choice': choice,
          if (confirmDeletion) 'confirmDeletion': true,
        },
      );
      _conflicts.removeWhere((c) => c['entryId'] == entryId && c['provider'] == provider);
      notifyListeners();
      await fetchIntegrations();
      return true;
    } catch (e) {
      debugPrint('Error resolving conflict: $e');
      return false;
    }
  }

  Future<void> scrobbleEpisode({
    required String animeTitle,
    String? animeId,
    required int episode,
    bool isCompleted = false,
    int? totalEpisodes,
  }) async {
    if (!_autoScrobble) return;
    if (!_isAniListConnected && !_isMalConnected) return;

    try {
      final dio = GetIt.I<DioClient>();
      Map<String, dynamic>? match;
      for (final entry in _entries) {
        if (animeId != null && animeId.isNotEmpty && entry['sourceId'] == animeId) {
          match = entry;
          break;
        }
        if (entry['title'] != null && entry['title'].toString().toLowerCase() == animeTitle.toLowerCase()) {
          match = entry;
          break;
        }
      }

      if (match != null) {
        await dio.post(
          '${ApiConstants.caliumBackendUrl}/api/tracking/progress',
          data: {
            'entryId': match['id'],
            'version': match['version'],
            'completedEpisodes': episode,
          },
        );
      } else {
        await dio.patch(
          '${ApiConstants.caliumBackendUrl}/api/tracking/entries',
          data: {
            if (animeId != null && animeId.isNotEmpty) 'sourceId': animeId,
            'title': animeTitle,
            ...?((totalEpisodes != null) ? {'totalEpisodes': totalEpisodes} : null),
            'confirmMapping': true,
            'value': {
              'progress': episode,
              'status': isCompleted ? 'completed' : 'watching',
            },
          },
        );
      }
    } catch (e) {
      debugPrint('Scrobble error: $e');
    }
  }
}
