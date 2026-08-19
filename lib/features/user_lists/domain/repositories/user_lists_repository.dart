import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';

abstract class UserListsRepository {
  Future<Either<Failure, List<UserListEntity>>> getMyLists();
  Future<Either<Failure, List<UserListEntity>>> getPublicLists();
  Future<Either<Failure, UserListEntity>> getListDetails(String listId);
  Future<Either<Failure, UserListEntity>> createList({
    required String name,
    String? description,
    bool isPublic = true,
  });
  Future<Either<Failure, void>> addAnimeToList({
    required String listId,
    required String animeId,
    required String animeName,
    String? poster,
  });
  Future<Either<Failure, void>> removeAnimeFromList({
    required String listId,
    required String animeId,
  });
  Future<Either<Failure, bool>> toggleLikeList(String listId, {bool? currentlyLiked});
}
