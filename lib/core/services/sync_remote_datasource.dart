import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/models/user_model.dart';

abstract class SyncRemoteDataSource {
  Future<UserModel?> refreshCurrentUser();
  Future<List<Map<String, dynamic>>> getRemoteHistory();
  Future<void> uploadHistory(List<Map<String, dynamic>> historyItems);
  Future<List<Map<String, dynamic>>> getRemoteFavorites();
  Future<void> uploadFavorites(List<Map<String, dynamic>> favoriteItems);
  Future<List<Map<String, dynamic>>> getLatestEpisodes();
  Future<List<Map<String, dynamic>>> getNotifications();
  Future<bool> registerDeviceToken({
    required String token,
    required String installationId,
    String platform = 'android',
  });
  Future<void> unregisterDeviceToken({required String installationId});
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  const SyncRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  @override
  Future<UserModel?> refreshCurrentUser() async {
    try {
      final response = await _dioClient.get('/api/auth/me');
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['success'] == true &&
          data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRemoteHistory() async {
    try {
      final response = await _dioClient.get('/api/sync/history');
      final data = response.data;
      if (data is Map<String, dynamic> && data['history'] is List) {
        return (data['history'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Geçmiş alınamadı: $e');
    }
  }

  @override
  Future<void> uploadHistory(List<Map<String, dynamic>> historyItems) async {
    if (historyItems.isEmpty) return;
    try {
      await _dioClient.post(
        '/api/sync/history',
        data: {'history': historyItems},
      );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRemoteFavorites() async {
    try {
      final response = await _dioClient.get('/api/sync/favorites');
      final data = response.data;
      if (data is Map<String, dynamic> && data['favorites'] is List) {
        return (data['favorites'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> uploadFavorites(List<Map<String, dynamic>> favoriteItems) async {
    if (favoriteItems.isEmpty) return;
    try {
      await _dioClient.post(
        '/api/sync/favorites',
        data: {'favorites': favoriteItems},
      );
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getLatestEpisodes() async {
    try {
      final response = await _dioClient.get('/api/anizium/latest');
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _dioClient.get('/api/notifications');
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        return (data['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> registerDeviceToken({
    required String token,
    required String installationId,
    String platform = 'android',
  }) async {
    try {
      await _dioClient.post(
        '/api/notifications/devices',
        data: {
          'token': token,
          'installationId': installationId,
          'platform': platform,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> unregisterDeviceToken({required String installationId}) async {
    try {
      await _dioClient.delete(
        '/api/notifications/devices',
        data: {'installationId': installationId},
      );
    } catch (_) {}
  }
}
