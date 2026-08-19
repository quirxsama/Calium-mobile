import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';

class GetFavoritesUseCase {
  const GetFavoritesUseCase({required LibraryRepository repository})
      : _repository = repository;

  final LibraryRepository _repository;

  Future<Either<Failure, List<FavoriteEntity>>> call() {
    return _repository.getFavorites();
  }
}
