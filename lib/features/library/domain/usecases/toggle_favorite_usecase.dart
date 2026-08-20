import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';

class ToggleFavoriteUseCase {
  const ToggleFavoriteUseCase({required this._repository});

  final LibraryRepository _repository;

  Future<Either<Failure, bool>> call(FavoriteEntity favorite) {
    return _repository.toggleFavorite(favorite);
  }
}
