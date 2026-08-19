import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';

abstract class LibraryRepository {
  Future<Either<Failure, List<FavoriteEntity>>> getFavorites();

  Future<Either<Failure, bool>> toggleFavorite(FavoriteEntity favorite);

  Future<Either<Failure, List<HistoryEntity>>> getHistory();

  Future<Either<Failure, void>> clearHistory();

  Future<Either<Failure, void>> syncWithCloud();
}
