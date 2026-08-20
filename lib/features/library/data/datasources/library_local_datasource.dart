import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/features/library/data/models/favorite_model.dart';
import 'package:calium_stream/features/library/data/models/history_model.dart';

abstract class LibraryLocalDataSource {
  Future<List<FavoriteModel>> getFavorites();
  Future<bool> toggleFavorite(FavoriteModel favorite);
  Future<bool> isFavorite(String animeId);
  Future<void> saveFavoritesBulk(List<FavoriteModel> favorites);
  Future<List<HistoryModel>> getHistory();
  Future<void> saveHistory(HistoryModel history);
  Future<void> saveHistoryBulk(List<HistoryModel> history);
  Future<void> deleteHistoryItem(String animeId);
  Future<void> clearHistory();
}

class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  Box get _favBox => Hive.box('favorites');
  Box get _histBox => Hive.box('history');
  Box get _favDeletedBox => Hive.box('favorites_deleted');

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    final list = <FavoriteModel>[];
    for (final key in _favBox.keys) {
      final data = _favBox.get(key);
      if (data is Map) {
        list.add(FavoriteModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  Future<bool> toggleFavorite(FavoriteModel favorite) async {
    if (_favBox.containsKey(favorite.animeId)) {
      await _favBox.delete(favorite.animeId);
      try {
        await _favDeletedBox.put(
          favorite.animeId,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (_) {}
      return false;
    } else {
      try {
        await _favDeletedBox.delete(favorite.animeId);
      } catch (_) {}
      await _favBox.put(favorite.animeId, favorite.toJson());
      return true;
    }
  }

  @override
  Future<bool> isFavorite(String animeId) async {
    return _favBox.containsKey(animeId);
  }

  @override
  Future<void> saveFavoritesBulk(List<FavoriteModel> favorites) async {
    for (final f in favorites) {
      // If locally marked as deleted, do not resurrect from cloud
      if (_favDeletedBox.containsKey(f.animeId)) continue;
      await _favBox.put(f.animeId, f.toJson());
    }
  }

  @override
  Future<List<HistoryModel>> getHistory() async {
    final list = <HistoryModel>[];
    for (final key in _histBox.keys) {
      final data = _histBox.get(key);
      if (data is Map) {
        list.add(HistoryModel.fromJson(Map<String, dynamic>.from(data)));
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> saveHistory(HistoryModel history) async {
    await _clearTombstone(history.animeId);
    await _histBox.put(history.animeId, history.toJson());
  }

  @override
  Future<void> saveHistoryBulk(List<HistoryModel> history) async {
    for (final h in history) {
      final existing = _histBox.get(h.animeId);
      if (existing is Map) {
        final localUpdated = (existing['updatedAt'] is num)
            ? (existing['updatedAt'] as num).toInt()
            : 0;
        final incoming = h.updatedAt.millisecondsSinceEpoch;
        // Cloud data must not roll back newer local progress
        if (localUpdated > 0 && incoming < localUpdated) continue;
      }
      final json = h.toJson();
      // Preserve precise resume position that cloud data doesn't carry
      if (existing is Map && existing['positionMs'] != null) {
        json['positionMs'] = existing['positionMs'];
      }
      // Preserve episode thumbnail captured during local playback
      if (existing is Map && existing['episodeThumb'] != null) {
        json['episodeThumb'] = existing['episodeThumb'];
      }
      await _histBox.put(h.animeId, json);
    }
  }

  Future<void> _clearTombstone(String animeId) async {
    try {
      final deletedBox = Hive.box('history_deleted');
      await deletedBox.delete(animeId);
    } catch (_) {}
  }

  @override
  Future<void> deleteHistoryItem(String animeId) async {
    await _histBox.delete(animeId);
    // Tombstone prevents cloud sync from re-adding the removed item
    try {
      final deletedBox = Hive.box('history_deleted');
      await deletedBox.put(animeId, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  @override
  Future<void> clearHistory() async {
    await _histBox.clear();
    try {
      await Hive.box('history_deleted').clear();
    } catch (_) {}
  }
}
