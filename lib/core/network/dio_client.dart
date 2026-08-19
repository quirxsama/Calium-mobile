import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/network/api_interceptors.dart';

/// A configured [Dio] wrapper that serves as the single HTTP client
/// for the entire application.
///
/// Registers the [AniziumHeaderInterceptor], [AuthInterceptor],
/// [DioCacheInterceptor], and [ErrorInterceptor] in the correct order so that:
///   1. Platform headers are attached first.
///   2. The auth token is injected.
///   3. Responses are cached in memory for instant screen transitions.
///   4. Errors are normalized into custom exceptions.
class DioClient {
  DioClient({required FlutterSecureStorage secureStorage})
      : _cacheOptions = CacheOptions(
          store: MemCacheStore(maxSize: 10485760, maxEntrySize: 1048576), // 10MB memory cache
          policy: CachePolicy.request,
          maxStale: const Duration(hours: 12),
          priority: CachePriority.normal,
          hitCacheOnErrorExcept: [401, 403],
        ),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.addAll([
      AniziumHeaderInterceptor(),
      AuthInterceptor(secureStorage: secureStorage),
      DioCacheInterceptor(options: _cacheOptions),
      ErrorInterceptor(),
    ]);
  }

  final Dio _dio;
  final CacheOptions _cacheOptions;

  /// Exposes the underlying [Dio] instance for advanced use-cases.
  Dio get dio => _dio;

  /// Cache options used by the cache interceptor.
  CacheOptions get cacheOptions => _cacheOptions;

  // ─── HTTP Verbs ──────────────────────────────────────────────

  /// Sends a GET request to the given [path].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Sends a POST request to the given [path].
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Sends a PUT request to the given [path].
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Sends a PATCH request to the given [path].
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Sends a DELETE request to the given [path].
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
