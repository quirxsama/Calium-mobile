import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/services/account_session.dart';
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
  Box get _favBox => AccountSession.instance.box('favorites');
  Box get _histBox => AccountSession.instance.box('history');
  Box get _favDeletedBox => AccountSession.instance.box('favorites_deleted');

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    final list = _favBox.values.whereType<Map>().map((data) => FavoriteModel.fromJson(Map<String, dynamic>.from(data))).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  @override
  Future<bool> toggleFavorite(FavoriteModel favorite) async {
    final box = _favBox;
    final deleted = _favDeletedBox;
    if (box.containsKey(favorite.animeId)) {
      await deleted.put(favorite.animeId, DateTime.now().millisecondsSinceEpoch);
      await box.delete(favorite.animeId);
      return false;
    }
    await deleted.delete(favorite.animeId);
    await box.put(favorite.animeId, favorite.toJson());
    return true;
  }

  @override
  Future<bool> isFavorite(String animeId) async => _favBox.containsKey(animeId);

  @override
  Future<void> saveFavoritesBulk(List<FavoriteModel> favorites) async {
    final box = _favBox;
    final deleted = _favDeletedBox;
    for (final f in favorites) {
      if (deleted.containsKey(f.animeId)) continue;
      await box.put(f.animeId, f.toJson());
    }
  }

  @override
  Future<List<HistoryModel>> getHistory() async {
    final list = _histBox.values.whereType<Map>().map((data) => HistoryModel.fromJson(Map<String, dynamic>.from(data))).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> saveHistory(HistoryModel history) async {
    final box = _histBox;
    final deleted = AccountSession.instance.box('history_deleted');
    final existing = box.get(history.animeId);
    await deleted.delete(history.animeId);
    await box.put(history.animeId, {
      ...history.toJson(),
      'dirty': true,
      'revision': ((existing is Map ? existing['revision'] as num? : null)?.toInt() ?? 0) + 1,
    });
  }

  @override
  Future<void> saveHistoryBulk(List<HistoryModel> history) async {
    final box = _histBox;
    final deleted = AccountSession.instance.box('history_deleted');
    for (final h in history) {
      if (deleted.containsKey(h.animeId)) continue;
      final existing = box.get(h.animeId);
      if (existing is Map && (existing['dirty'] == true || ((existing['updatedAt'] as num?)?.toInt() ?? 0) >= h.updatedAt.millisecondsSinceEpoch)) continue;
      final json = h.toJson();
      if (existing is Map && h.episodeThumb.isEmpty) json['episodeThumb'] = existing['episodeThumb'];
      await box.put(h.animeId, json);
    }
  }

  @override
  Future<void> deleteHistoryItem(String animeId) async {
    final box = _histBox;
    final deleted = AccountSession.instance.box('history_deleted');
    await deleted.put(animeId, DateTime.now().millisecondsSinceEpoch);
    await box.delete(animeId);
  }

  @override
  Future<void> clearHistory() async {
    final box = _histBox;
    final deleted = AccountSession.instance.box('history_deleted');
    await deleted.putAll({for (final key in box.keys) key: DateTime.now().millisecondsSinceEpoch});
    await box.clear();
  }
}
