import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/social/data/datasources/social_remote_datasource.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';
import 'package:calium_stream/features/social/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl({
    required SocialRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SocialRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<RoomEntity>>> getPublicRooms() async {
    try {
      final rooms = await _remoteDataSource.getPublicRooms();
      return Right(rooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> joinRoomByCode(String code) async {
    try {
      final room = await _remoteDataSource.joinRoomByCode(code);
      return Right(room);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> createRoom({
    required String animeId,
    required String animeName,
    required String episodeId,
    String? episodeName,
    String? poster,
    bool isPublic = true,
  }) async {
    try {
      final room = await _remoteDataSource.createRoom(
        animeId: animeId,
        animeName: animeName,
        episodeId: episodeId,
        episodeName: episodeName,
        poster: poster,
        isPublic: isPublic,
      );
      return Right(room);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoomEntity>>> getMyRooms() async {
    try {
      final rooms = await _remoteDataSource.getMyRooms();
      return Right(rooms);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> closeRoom(String roomId) async {
    try {
      await _remoteDataSource.closeRoom(roomId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveRoom(String roomId) async {
    try {
      await _remoteDataSource.leaveRoom(roomId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SocialFriendEntity>>> getFriends() async {
    try {
      final friends = await _remoteDataSource.getFriends();
      return Right(friends);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
