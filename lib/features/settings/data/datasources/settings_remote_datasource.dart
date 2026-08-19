import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/models/user_model.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';

abstract class SettingsRemoteDataSource {
  Future<UserEntity> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
    bool? dndEnabled,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
    bool? dndEnabled,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (displayName != null) payload['displayName'] = displayName;
      if (bio != null) payload['bio'] = bio;
      if (avatarUrl != null) payload['avatarUrl'] = avatarUrl;
      if (isPrivate != null) payload['isPrivate'] = isPrivate;
      if (dndEnabled != null) payload['dndEnabled'] = dndEnabled;

      final response = await _dioClient.patch(
        '/api/account',
        data: payload,
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      throw ServerException(message: data['error']?.toString() ?? 'Profil güncellenemedi.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/account/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == false) {
        throw ServerException(message: data['error']?.toString() ?? 'Şifre güncellenemedi.');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
