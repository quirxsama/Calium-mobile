import 'package:equatable/equatable.dart';

/// Base failure type for the domain layer.
///
/// Repositories map data-layer [Exception]s to concrete [Failure] subtypes
/// and return them via `Either<Failure, T>`.
sealed class Failure extends Equatable {
  const Failure({required this.message});

  /// A user-presentable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The remote server returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// A local cache operation failed (read, write, or expiry).
final class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// No network connectivity or a connection timeout occurred.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// The user's session is invalid, expired, or unauthorized.
final class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}
