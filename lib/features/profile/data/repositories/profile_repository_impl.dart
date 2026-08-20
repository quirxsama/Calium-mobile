import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';
import 'package:calium_stream/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this._remoteDataSource});

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String username) async {
    try {
      final res = await _remoteDataSource.getUserProfile(username);
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getCurrentUserProfile() async {
    try {
      final res = await _remoteDataSource.getCurrentUserProfile();
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> toggleFollow(String username) async {
    try {
      final res = await _remoteDataSource.toggleFollow(username);
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
