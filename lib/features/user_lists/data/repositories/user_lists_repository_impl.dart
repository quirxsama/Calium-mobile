import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/user_lists/data/datasources/user_lists_remote_datasource.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';
import 'package:calium_stream/features/user_lists/domain/repositories/user_lists_repository.dart';

class UserListsRepositoryImpl implements UserListsRepository {
  const UserListsRepositoryImpl({required this._remoteDataSource});

  final UserListsRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<UserListEntity>>> getMyLists() async {
    try {
      final res = await _remoteDataSource.getMyLists();
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserListEntity>>> getPublicLists() async {
    try {
      final res = await _remoteDataSource.getPublicLists();
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserListEntity>> getListDetails(String listId) async {
    try {
      final res = await _remoteDataSource.getListDetails(listId);
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserListEntity>> createList({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final res = await _remoteDataSource.createList(
        name: name,
        description: description,
        isPublic: isPublic,
      );
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addAnimeToList({
    required String listId,
    required String animeId,
    required String animeName,
    String? poster,
  }) async {
    try {
      await _remoteDataSource.addAnimeToList(
        listId: listId,
        animeId: animeId,
        animeName: animeName,
        poster: poster,
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

  @override
  Future<Either<Failure, void>> removeAnimeFromList({
    required String listId,
    required String animeId,
  }) async {
    try {
      await _remoteDataSource.removeAnimeFromList(
        listId: listId,
        animeId: animeId,
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

  @override
  Future<Either<Failure, bool>> toggleLikeList(String listId, {bool? currentlyLiked}) async {
    try {
      final res = await _remoteDataSource.toggleLikeList(listId, currentlyLiked: currentlyLiked);
      return Right(res);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteList(String listId) async {
    try {
      await _remoteDataSource.deleteList(listId);
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
