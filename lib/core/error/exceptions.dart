// Custom exceptions for the data layer.
//
// These are thrown by data sources and interceptors, then caught by
// repository implementations and mapped to [Failure] subtypes.

/// Thrown when the server responds with an error status code.
class ServerException implements Exception {
  const ServerException({
    this.statusCode = 500,
    required this.message,
  });

  /// The HTTP status code returned by the server.
  final int statusCode;

  /// A human-readable error message from the server response.
  final String message;

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

/// Thrown when a local cache read/write operation fails.
class CacheException implements Exception {
  const CacheException({this.message = 'Cache operation failed'});

  final String message;

  @override
  String toString() => 'CacheException(message: $message)';
}

/// Thrown when the device has no internet connectivity or the request times out.
class NetworkException implements Exception {
  const NetworkException({this.message = 'Network unavailable'});

  final String message;

  @override
  String toString() => 'NetworkException(message: $message)';
}

/// Thrown when an authentication/authorization error occurs (e.g. expired token).
class AuthException implements Exception {
  const AuthException({this.message = 'Authentication failed'});

  final String message;

  @override
  String toString() => 'AuthException(message: $message)';
}
