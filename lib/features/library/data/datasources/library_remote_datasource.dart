import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/library/data/models/favorite_model.dart';
import 'package:calium_stream/features/library/data/models/history_model.dart';

abstract class LibraryRemoteDataSource {
  Future<List<FavoriteModel>> fetchFavoritesFromCloud();
  Future<List<HistoryModel>> fetchHistoryFromCloud();
  Future<void> syncFavorites(List<FavoriteModel> favorites);
  Future<void> syncHistory(List<HistoryModel> history);
}

class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  const LibraryRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<List<FavoriteModel>> fetchFavoritesFromCloud() async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.caliumBackendUrl}/api/sync/favorites',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['favorites'] is List) {
        return (data['favorites'] as List)
            .map((f) => FavoriteModel.fromJson(f as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<HistoryModel>> fetchHistoryFromCloud() async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.caliumBackendUrl}/api/sync/history',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['history'] is List) {
        return (data['history'] as List)
            .map((h) => HistoryModel.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> syncFavorites(List<FavoriteModel> favorites) async {
    try {
      await _dioClient.post(
        '${ApiConstants.caliumBackendUrl}/api/sync/favorites',
        data: {'favorites': favorites.map((f) => f.toJson()).toList()},
      );
    } catch (_) {
      // Background sync failure is handled silently
    }
  }

  @override
  Future<void> syncHistory(List<HistoryModel> history) async {
    try {
      await _dioClient.post(
        '${ApiConstants.caliumBackendUrl}/api/sync/history',
        data: {'history': history.map((h) => h.toJson()).toList()},
      );
    } catch (_) {
      // Background sync failure is handled silently
    }
  }
}
