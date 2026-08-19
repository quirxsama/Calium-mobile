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
  Future<void> clearHistory();
}

class LibraryLocalDataSourceImpl implements LibraryLocalDataSource {
  Box get _favBox => Hive.box('favorites');
  Box get _histBox => Hive.box('history');

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
      return false;
    } else {
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
    await _histBox.put(history.animeId, history.toJson());
  }

  @override
  Future<void> saveHistoryBulk(List<HistoryModel> history) async {
    for (final h in history) {
      await _histBox.put(h.animeId, h.toJson());
    }
  }

  @override
  Future<void> clearHistory() async {
    await _histBox.clear();
  }
}
