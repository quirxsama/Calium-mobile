import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';

class SyncService with WidgetsBindingObserver {
  SyncService({
    required SyncRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

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

      // A. Prepare local history items to upload to server
      final List<Map<String, dynamic>> localItemsToUpload = [];
      for (final key in historyBox.keys) {
        final val = historyBox.get(key);
        if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          final animeId = map['animeId']?.toString() ?? key.toString();
          final animeName = map['animeName']?.toString() ?? map['title']?.toString() ?? 'Anime';
          final episodeId = map['episodeId']?.toString() ?? 'ep-1';
          final episodeName = map['episodeName']?.toString() ?? 'Bölüm 1';
          final poster = map['poster']?.toString() ?? map['posterPath']?.toString();
          final episodeNumber = (map['episodeNumber'] as num?)?.toInt() ?? (map['episode'] as num?)?.toInt();
          final seasonNumber = (map['seasonNumber'] as num?)?.toInt() ?? (map['season'] as num?)?.toInt();
          final progress = (map['progress'] as num?)?.toDouble() ?? (map['position'] as num?)?.toDouble() ?? 0.0;
          final duration = (map['duration'] as num?)?.toDouble() ?? 0.0;
          final updatedAt = (map['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

          localItemsToUpload.add({
            'animeId': animeId,
            'animeName': animeName,
            'poster': poster,
            'episodeId': episodeId,
            'episodeName': episodeName,
            'episodeNumber': episodeNumber,
            'seasonNumber': seasonNumber,
            'progress': progress.round(),
            'duration': duration.round(),
            'updatedAt': updatedAt,
          });
        }
      }

      // Upload local items to server
      if (localItemsToUpload.isNotEmpty) {
        await _remoteDataSource.uploadHistory(localItemsToUpload);
      }

      // B. Download latest server history and merge into local Hive
      final serverHistory = await _remoteDataSource.getRemoteHistory();
      for (final sItem in serverHistory) {
        final animeId = sItem['animeId']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          final existing = historyBox.get(animeId);
          int localUpdated = 0;
          if (existing is Map && existing['updatedAt'] is num) {
            localUpdated = (existing['updatedAt'] as num).toInt();
          }

          final serverUpdated = (sItem['updatedAt'] as num?)?.toInt() ?? 0;
          if (serverUpdated >= localUpdated) {
            await historyBox.put(animeId, {
              'animeId': animeId,
              'animeName': sItem['animeName'],
              'poster': sItem['poster'],
              'episodeId': sItem['episodeId'],
              'episodeName': sItem['episodeName'],
              'episodeNumber': sItem['episodeNumber'],
              'seasonNumber': sItem['seasonNumber'],
              'progress': sItem['progress'],
              'duration': sItem['duration'],
              'updatedAt': serverUpdated,
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _syncFavorites() async {
    try {
      final favoritesBox = Hive.box('favorites');
      final serverFavorites = await _remoteDataSource.getRemoteFavorites();

      for (final item in serverFavorites) {
        final animeId = item['animeId']?.toString() ?? item['id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
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
