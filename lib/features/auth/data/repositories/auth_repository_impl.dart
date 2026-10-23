import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._secureStorage,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    final sessionState = AccountSession.instance;
    final generation = sessionState.invalidate();
    try {
      final (user, token) = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      if (generation != sessionState.generation) throw StateError('Account changed');
      if (token.isEmpty) throw StateError('Missing session token');
      if (token.isNotEmpty) {
        await _secureStorage.write(
          key: StorageKeys.authToken,
          value: token,
        );
      }
      await _secureStorage.write(
        key: StorageKeys.currentUser,
        value: user.username,
      );
      if (!await sessionState.activate(user.id, generation)) throw StateError('Account changed');
      return Right(user);
    } on ServerException catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      await sessionState.activate(null, generation);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final sessionState = AccountSession.instance;
    final generation = sessionState.invalidate();
    try {
      final (user, token) = await _remoteDataSource.register(
        email: email,
        username: username,
        password: password,
      );
      if (generation != sessionState.generation) throw StateError('Account changed');
      if (token.isEmpty) throw StateError('Missing session token');
      if (token.isNotEmpty) {
        await _secureStorage.write(
          key: StorageKeys.authToken,
          value: token,
        );
      }
      await _secureStorage.write(
        key: StorageKeys.currentUser,
        value: user.username,
      );
      if (!await sessionState.activate(user.id, generation)) throw StateError('Account changed');
      return Right(user);
    } on ServerException catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      await sessionState.activate(null, generation);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    final sessionState = AccountSession.instance;
    final generation = sessionState.generation;
    try {
      final token = await _secureStorage.read(key: StorageKeys.authToken);
      if (token == null || token.isEmpty) {
        return const Left(AuthFailure(message: 'Oturum bulunamadı'));
      }
      final user = await _remoteDataSource.getCurrentUser();
      if (generation != sessionState.generation) throw StateError('Account changed');
      await _secureStorage.write(
        key: StorageKeys.currentUser,
        value: user.username,
      );
      if (!await sessionState.activate(user.id, generation)) throw StateError('Account changed');
      return Right(user);
    } on ServerException catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      await sessionState.activate(null, generation);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      await sessionState.activate(null, generation);
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    final session = AccountSession.instance;
    final generation = session.invalidate();
    try {
      await _remoteDataSource.logout();
    } finally {
      if (generation == session.generation) {
        await _secureStorage.delete(key: StorageKeys.authToken);
        await _secureStorage.delete(key: StorageKeys.currentUser);
        await session.activate(null, generation);
      }
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithOAuth({
    required String provider,
    required Future<void> Function(String url) onOpenUrl,
  }) async {
    final sessionState = AccountSession.instance;
    final generation = sessionState.invalidate();
    try {
      final session = await _remoteDataSource.startOAuth(
        provider: provider,
        intent: 'login',
      );
      await onOpenUrl(session.authorizationUrl);
      final (user, token) = await _remoteDataSource.pollOAuthLogin(
        transactionId: session.transactionId,
        verifier: session.verifier,
      );
      if (generation != sessionState.generation) throw StateError('Account changed');
      if (token.isEmpty) throw StateError('Missing session token');
      if (token.isNotEmpty) {
        await _secureStorage.write(
          key: StorageKeys.authToken,
          value: token,
        );
      }
      await _secureStorage.write(
        key: StorageKeys.currentUser,
        value: user.username,
      );
      if (!await sessionState.activate(user.id, generation)) throw StateError('Account changed');
      return Right(user);
    } on ServerException catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      await sessionState.activate(null, generation);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      await sessionState.activate(null, generation);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
