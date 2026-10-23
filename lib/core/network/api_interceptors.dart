import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/error/exceptions.dart';

// ─── Anizium Header Interceptor ─────────────────────────────────

/// Injects the authentic Anizium platform headers into outgoing requests.
///
/// Uses the Cloudflare tokens and headers defined in `.env.local`
/// matching the exact request pattern used in Calium web.
class AniziumHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only apply Anizium headers to Anizium API requests
    final isAnizium = options.uri.host.contains('anizium.co') ||
        options.path.startsWith('/page/') ||
        options.path.startsWith('/anime/');

    if (isAnizium) {
      options.headers['origin'] = ApiConstants.origin;
      options.headers['referer'] = ApiConstants.referer;
      options.headers['cf-control'] = ApiConstants.cfControl;
      options.headers['user-session'] = ApiConstants.userSession;
      options.headers['user-agent'] = ApiConstants.userAgent;
      options.headers['accept'] = 'application/json, text/plain, */*';
      options.headers['accept-language'] = 'tr-TR,tr;q=0.9,en;q=0.8';
      options.headers['sec-fetch-site'] = 'same-site';
      options.headers['sec-fetch-mode'] = 'cors';
      options.headers['sec-fetch-dest'] = 'empty';
    }

    handler.next(options);
  }
}

// ─── Auth Interceptor ───────────────────────────────────────────

/// Attaches the Calium user session JWT and calium_session cookie only to Calium backend endpoints.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this._secureStorage});

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only attach user token to Calium backend endpoints (auth, sync, profile, rooms)
    final session = AccountSession.instance;
    final generation = session.generation;
    final isCaliumEndpoint = options.uri.origin == Uri.parse(ApiConstants.caliumBackendUrl).origin;
    options.extra['sessionGeneration'] = generation;

    if (isCaliumEndpoint) {
      options.extra.addAll(CacheOptions(store: null, policy: CachePolicy.noCache).toExtra());
      final path = options.uri.path;
      final publicAuth = path.startsWith('/api/auth/');
      final accountRequest = path.startsWith('/api/sync') || path.startsWith('/api/tracking') || path.startsWith('/api/integrations');
      if (accountRequest && (!session.ready || session.userId == null)) {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.cancel));
        return;
      }
      if (!session.ready && !publicAuth) {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.cancel));
        return;
      }
      options.headers['origin'] = ApiConstants.caliumBackendUrl;
      options.headers['referer'] = '${ApiConstants.caliumBackendUrl}/';
      final token = await _secureStorage.read(key: StorageKeys.authToken);
      if (generation != session.generation) {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.cancel));
        return;
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        options.headers['Cookie'] = 'calium_session=$token';
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra['sessionGeneration'] != AccountSession.instance.generation) {
      handler.reject(DioException(requestOptions: response.requestOptions, type: DioExceptionType.cancel));
      return;
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isCaliumAuth = err.requestOptions.path.startsWith('/api/auth') ||
        err.requestOptions.path.startsWith('/api/account');

    if (isCaliumAuth && err.response?.statusCode == 401 &&
        err.requestOptions.extra['sessionGeneration'] == AccountSession.instance.generation) {
      final generation = AccountSession.instance.invalidate();
      await _secureStorage.delete(key: StorageKeys.authToken);
      await _secureStorage.delete(key: StorageKeys.refreshToken);
      await AccountSession.instance.activate(null, generation);
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: const AuthException(message: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
        ),
      );
      return;
    }
    handler.next(err);
  }
}

// ─── Error Interceptor ──────────────────────────────────────────

/// Maps raw [DioException]s to the application's custom exception types.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: err.type,
            error: NetworkException(
              message: 'Bağlantı zaman aşımına uğradı: ${err.message ?? ''}',
            ),
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 500;
        final responseData = err.response?.data;
        String message = 'Sunucu hatası ($statusCode)';

        if (responseData is Map<String, dynamic>) {
          message = (responseData['message'] as String?) ??
              (responseData['error'] as String?) ??
              message;
        }

        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: ServerException(statusCode: statusCode, message: message),
          ),
        );
        return;

      case DioExceptionType.cancel:
        handler.reject(err);
        return;

      case DioExceptionType.badCertificate:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: err.type,
            error: const NetworkException(
              message: 'Geçersiz SSL sertifikası',
            ),
          ),
        );
        return;

      case DioExceptionType.unknown:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: err.type,
            error: NetworkException(
              message: err.message ?? 'Beklenmeyen bir ağ hatası oluştu',
            ),
          ),
        );
        return;
    }
  }
}
