import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';

class SyncService with WidgetsBindingObserver {
  SyncService({
    required this._remoteDataSource,
    required this._secureStorage,
  });

  final SyncRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  Timer? _periodicTimer;
  bool _isSyncing = false;

  // Stream for live sync status and user updates
  final _userUpdateController = StreamController<UserEntity?>.broadcast();
  Stream<UserEntity?> get onUserUpdated => _userUpdateController.stream;

  final _syncEventController = StreamController<void>.broadcast();
  Stream<void> get onSyncCompleted => _syncEventController.stream;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _periodicTimer?.cancel();
    // Run full sync every 45 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      syncNow();
    });

    // Run initial sync after a brief delay
    Timer(const Duration(seconds: 2), () {
      syncNow();
    });
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User returned to the app: trigger immediate sync to fetch website progress
      syncNow();
    }
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final token = await _secureStorage.read(key: StorageKeys.authToken);
      if (token == null || token.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 1. Silent Session & Profile Refresh (/api/auth/me)
      final user = await _remoteDataSource.refreshCurrentUser();
      if (user != null) {
        await _secureStorage.write(key: StorageKeys.currentUser, value: user.username);
        _userUpdateController.add(user);
      }

      // 2. Bidirectional History Sync (/api/sync/history)
      await _syncWatchHistory();

      // 3. Bidirectional Favorites Sync (/api/sync/favorites)
      await _syncFavorites();

      _syncEventController.add(null);
    } catch (_) {
      // Background sync is silent & fault-tolerant
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncWatchHistory() async {
    try {
      final historyBox = Hive.box('history');

      int toEpochMs(dynamic v) {
        if (v is num) return v.toInt();
        if (v is String) {
          return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
        }
        return 0;
      }

      double normalizeProgress(dynamic v) {
        final raw = (v as num?)?.toDouble() ?? 0.0;
        final p = raw > 1.0 ? raw / 100.0 : raw;
        return p.clamp(0.0, 1.0);
      }

      // A. Prepare only locally changed (dirty) history items to upload
      final List<Map<String, dynamic>> localItemsToUpload = [];
      for (final key in historyBox.keys) {
        final val = historyBox.get(key);
        if (val is! Map) continue;
        final map = Map<String, dynamic>.from(val);
        if (map['dirty'] != true) continue;

        final animeId = map['animeId']?.toString() ?? key.toString();
        if (animeId.isEmpty) continue;

        final durationSec = (map['duration'] as num?)?.toInt() ?? 0;
        final progress = normalizeProgress(map['progress']);
        final positionMs = (map['positionMs'] as num?)?.toInt() ??
            (progress > 0 && durationSec > 0
                ? (progress * durationSec * 1000).round()
                : 0);

        localItemsToUpload.add({
          'animeId': animeId,
          'animeName': map['animeName']?.toString() ?? 'Anime',
          'poster': map['poster']?.toString() ?? '',
          'episodeId': map['episodeId']?.toString() ?? 'ep-1',
          'episodeName': map['episodeName']?.toString() ?? 'Bölüm 1',
          'episodeNumber': (map['episodeNumber'] as num?)?.toInt() ?? 1,
          'seasonNumber': (map['seasonNumber'] as num?)?.toInt() ?? 1,
          'progress': progress,
          'duration': durationSec,
          'positionMs': positionMs,
          'updatedAt': toEpochMs(map['updatedAt']),
        });
      }

      // Upload local items to server, then mark them as synced
      if (localItemsToUpload.isNotEmpty) {
        await _remoteDataSource.uploadHistory(localItemsToUpload);
        for (final item in localItemsToUpload) {
          final animeId = item['animeId'] as String? ?? '';
          if (animeId.isEmpty) continue;
          final existing = historyBox.get(animeId);
          if (existing is Map) {
            final cleaned = Map<String, dynamic>.from(existing);
            cleaned['dirty'] = false;
            await historyBox.put(animeId, cleaned);
          }
        }
      }

      // B. Download latest server history and merge into local Hive
      final serverHistory = await _remoteDataSource.getRemoteHistory();
      Box? deletedBox;
      try {
        deletedBox = Hive.box('history_deleted');
      } catch (_) {}

      for (final sItem in serverHistory) {
        final animeId = sItem['animeId']?.toString();
        if (animeId == null || animeId.isEmpty) continue;

        final existing = historyBox.get(animeId);
        final existingMap =
            existing is Map ? Map<String, dynamic>.from(existing) : null;

        final serverUpdated = toEpochMs(sItem['updatedAt']);
        final localUpdated =
            existingMap == null ? 0 : toEpochMs(existingMap['updatedAt']);

        // Respect locally removed items (tombstone) unless server has newer data
        if (deletedBox != null) {
          final tombstone = (deletedBox.get(animeId) as num?)?.toInt() ?? 0;
          if (tombstone > 0 && serverUpdated <= tombstone) continue;
          if (tombstone > 0 && serverUpdated > tombstone) {
            await deletedBox.delete(animeId);
          }
        }

        // Keep newer local data (e.g. watched offline) untouched
        if (existingMap != null && serverUpdated < localUpdated) continue;

        final serverProgress = normalizeProgress(sItem['progress']);
        final serverDuration = (sItem['duration'] as num?)?.toInt() ??
            (existingMap?['duration'] as num?)?.toInt() ??
            0;
        final serverPositionMs = (sItem['positionMs'] as num?)?.toInt() ??
            (existingMap?['positionMs'] as num?)?.toInt() ??
            (serverProgress > 0 && serverDuration > 0
                ? (serverProgress * serverDuration * 1000).round()
                : 0);

        await historyBox.put(animeId, {
          'animeId': animeId,
          'animeName': sItem['animeName']?.toString() ??
              existingMap?['animeName']?.toString() ??
              'Anime',
          'poster': sItem['poster']?.toString() ??
              existingMap?['poster']?.toString() ??
              '',
          'episodeThumb': sItem['episodeThumb']?.toString() ??
              existingMap?['episodeThumb']?.toString() ??
              '',
          'episodeId': sItem['episodeId']?.toString() ??
              existingMap?['episodeId']?.toString() ??
              'ep-1',
          'episodeName': sItem['episodeName']?.toString() ??
              existingMap?['episodeName']?.toString() ??
              'Bölüm 1',
          'episodeNumber': (sItem['episodeNumber'] as num?)?.toInt() ??
              (existingMap?['episodeNumber'] as num?)?.toInt() ??
              1,
          'seasonNumber': (sItem['seasonNumber'] as num?)?.toInt() ??
              (existingMap?['seasonNumber'] as num?)?.toInt() ??
              1,
          'progress': serverProgress,
          'duration': serverDuration,
          'positionMs': serverPositionMs,
          'updatedAt': serverUpdated > 0 ? serverUpdated : localUpdated,
        });
      }
    } catch (_) {}
  }

  Future<void> _syncFavorites() async {
    try {
      final favoritesBox = Hive.box('favorites');
      Box? favDeletedBox;
      try {
        favDeletedBox = Hive.box('favorites_deleted');
      } catch (_) {}

      // 1. Prepare local favorites to upload to server
      final List<Map<String, dynamic>> localFavoritesToUpload = [];
      for (final key in favoritesBox.keys) {
        final val = favoritesBox.get(key);
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          final animeId = map['animeId']?.toString() ?? map['id']?.toString() ?? key.toString();
          if (animeId.isNotEmpty && (favDeletedBox == null || !favDeletedBox.containsKey(animeId))) {
            localFavoritesToUpload.add({
              'id': animeId,
              'name': map['name']?.toString() ?? '',
              'poster': map['poster']?.toString() ?? map['posterUrl']?.toString() ?? '',
              'addedAt': map['addedAt'] is num ? map['addedAt'] : DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }

      // If we have local changes or deletions, upload to cloud
      await _remoteDataSource.uploadFavorites(localFavoritesToUpload);

      // 2. Fetch server favorites and add any new items not deleted locally
      final serverFavorites = await _remoteDataSource.getRemoteFavorites();
      for (final item in serverFavorites) {
        final animeId = item['animeId']?.toString() ?? item['id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          if (favDeletedBox != null && favDeletedBox.containsKey(animeId)) continue;
          if (!favoritesBox.containsKey(animeId)) {
            await favoritesBox.put(animeId, item);
          }
        }
      }
    } catch (_) {}
  }

  void dispose() {
    stop();
    _userUpdateController.close();
    _syncEventController.close();
  }
}
