import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<AnimeEntity>>> searchAnime({
    required String query,
    int page = 1,
    String? genreId,
    String? type,
  });
}
