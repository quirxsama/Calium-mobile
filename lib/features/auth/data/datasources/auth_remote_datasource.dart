import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

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

  Future<({String authorizationUrl, String transactionId, String verifier})> startOAuth({
    required String provider,
    required String intent,
  });

  Future<(UserModel, String token)> pollOAuthLogin({
    required String transactionId,
    required String verifier,
  });

  Future<bool> pollOAuthLink({
    required String transactionId,
    required String verifier,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required this._dioClient});

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
    }
  }

  @override
  Future<({String authorizationUrl, String transactionId, String verifier})> startOAuth({
    required String provider,
    required String intent,
  }) async {
    try {
      const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
      final random = Random.secure();
      final verifier = List.generate(43, (_) => charset[random.nextInt(charset.length)]).join();
      final challenge = base64Url.encode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');

      final response = await _dioClient.post(
        '${ApiConstants.caliumBackendUrl}/api/auth/oauth/$provider/start',
        data: {
          'intent': intent,
          'platform': 'mobile',
          'challenge': challenge,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return (
        authorizationUrl: data['authorizationUrl'] as String,
        transactionId: data['transactionId'] as String,
        verifier: verifier,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<(UserModel, String token)> pollOAuthLogin({
    required String transactionId,
    required String verifier,
  }) async {
    const maxAttempts = 120;
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      try {
        final response = await _dioClient.post(
          '${ApiConstants.caliumBackendUrl}/api/auth/oauth/exchange',
          data: {
            'transactionId': transactionId,
            'verifier': verifier,
          },
        );

        final data = response.data as Map<String, dynamic>;
        if (data['pending'] == true) {
          continue;
        }

        if (data['success'] == true && data['token'] != null && data['user'] != null) {
          final userJson = data['user'] as Map<String, dynamic>;
          final token = data['token'] as String;
          return (UserModel.fromJson(userJson), token);
        }

        if (data['error'] != null) {
          throw ServerException(message: data['error'].toString());
        }
      } on DioException catch (e) {
        final err = e.response?.data;
        if (err is Map && err['error'] != null) {
          final msg = err['error'].toString();
          if (msg != 'pending') {
            throw ServerException(message: msg);
          }
        }
      } catch (e) {
        if (e is ServerException) rethrow;
      }
    }
    throw const ServerException(message: 'Oturum zaman aşımına uğradı');
  }

  @override
  Future<bool> pollOAuthLink({
    required String transactionId,
    required String verifier,
  }) async {
    const maxAttempts = 120;
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      try {
        final response = await _dioClient.post(
          '${ApiConstants.caliumBackendUrl}/api/auth/oauth/exchange',
          data: {
            'transactionId': transactionId,
            'verifier': verifier,
          },
        );

        final data = response.data as Map<String, dynamic>;
        if (data['pending'] == true) {
          continue;
        }

        if (data['linked'] == true) {
          return true;
        }

        if (data['error'] != null) {
          throw ServerException(message: data['error'].toString());
        }
      } on DioException catch (e) {
        final err = e.response?.data;
        if (err is Map && err['error'] != null) {
          final msg = err['error'].toString();
          if (msg != 'pending') {
            throw ServerException(message: msg);
          }
        }
      } catch (e) {
        if (e is ServerException) rethrow;
      }
    }
    throw const ServerException(message: 'Bağlantı zaman aşımına uğradı');
  }
}
