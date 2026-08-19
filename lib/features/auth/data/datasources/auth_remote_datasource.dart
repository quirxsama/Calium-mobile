import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<(UserModel, String token)> login({
    required String email,
    required String password,
  });

  Future<(UserModel, String token)> register({
    required String email,
    required String username,
    required String password,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<(UserModel, String token)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.caliumBackendUrl}/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      String token = data['token'] as String? ?? data['sessionToken'] as String? ?? '';

      if (token.isEmpty) {
        final setCookie = response.headers['set-cookie']?.join(';') ?? '';
        final match = RegExp(r'calium_session=([^;]+)').firstMatch(setCookie);
        if (match != null) {
          token = match.group(1) ?? '';
        }
      }

      return (UserModel.fromJson(userJson), token);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<(UserModel, String token)> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.caliumBackendUrl}/api/auth/register',
        data: {
          'email': email,
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      String token = data['token'] as String? ?? data['sessionToken'] as String? ?? '';

      if (token.isEmpty) {
        final setCookie = response.headers['set-cookie']?.join(';') ?? '';
        final match = RegExp(r'calium_session=([^;]+)').firstMatch(setCookie);
        if (match != null) {
          token = match.group(1) ?? '';
        }
      }

      return (UserModel.fromJson(userJson), token);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get('${ApiConstants.caliumBackendUrl}/api/auth/me');
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return UserModel.fromJson(userJson);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dioClient.post('${ApiConstants.caliumBackendUrl}/api/auth/logout');
    } catch (_) {
      // Best-effort logout
    }
  }
}
