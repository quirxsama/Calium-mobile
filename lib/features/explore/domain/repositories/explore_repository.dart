import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

abstract class ExploreRepository {
  Future<Either<Failure, List<AnimeEntity>>> getCatalog({
    required String kind, // 'series', 'movie', 'trdub', 'genre'
    String? genreId,
    int page = 1,
  });
}
