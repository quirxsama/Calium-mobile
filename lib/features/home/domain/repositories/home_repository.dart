import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/entities/home_feed_entity.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeFeedEntity>> getHomeFeed();

  Future<Either<Failure, List<AnimeEntity>>> getLatestEpisodes({int page = 1});

  Future<Either<Failure, List<AnimeEntity>>> getTopAnime({int page = 1});
}
