import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/settings/data/datasources/settings_remote_datasource.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
    bool? dndEnabled,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required this._remoteDataSource});

  final SettingsRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
    bool? dndEnabled,
  }) async {
    try {
      final user = await _remoteDataSource.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        isPrivate: isPrivate,
        dndEnabled: dndEnabled,
      );
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
