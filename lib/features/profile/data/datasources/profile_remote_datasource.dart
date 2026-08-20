import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/profile/data/models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String username);
  Future<UserProfileModel> getCurrentUserProfile();
  Future<String> toggleFollow(String username);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl({
    required this._dioClient,
    required this._secureStorage,
  });

  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<UserProfileModel> getUserProfile(String username) async {
    try {
      final response = await _dioClient.get('/api/users/$username');
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true) {
        return UserProfileModel.fromJson(data);
      }
      throw ServerException(message: data['error']?.toString() ?? 'Kullanıcı bulunamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Profil yüklenemedi: $e');
    }
  }

  @override
  Future<UserProfileModel> getCurrentUserProfile() async {
    try {
      final currentUsername = await _secureStorage.read(key: StorageKeys.currentUser);
      if (currentUsername != null && currentUsername.isNotEmpty) {
        return await getUserProfile(currentUsername);
      }

      final meRes = await _dioClient.get('/api/auth/me');
      final meData = meRes.data;
      if (meData is Map<String, dynamic> && meData['user'] != null) {
        final user = meData['user'] as Map<String, dynamic>;
        final username = user['username']?.toString();
        if (username != null && username.isNotEmpty) {
          return await getUserProfile(username);
        }
        return UserProfileModel.fromJson(meData);
      }
      throw const ServerException(message: 'Giriş yapılmamış.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Profil yüklenemedi: $e');
    }
  }

  @override
  Future<String> toggleFollow(String username) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>('/api/users/$username/follow');
      final data = response.data;
      if (data != null) {
        return data['status']?.toString() ?? 'followed';
      }
      return 'followed';
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'İşlem başarısız: $e');
    }
  }
}
