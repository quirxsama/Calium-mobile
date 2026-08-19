import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';

abstract class AnimeDetailRepository {
  Future<Either<Failure, AnimeDetailEntity>> getAnimeDetail(String animeId);

  Future<Either<Failure, List<EpisodeEntity>>> getEpisodes({
    required String animeId,
    required int season,
  });

  Future<Either<Failure, List<CastEntity>>> getCast(String tmdbId);

  Future<Either<Failure, List<AnimeEntity>>> getSimilarAnime(String animeId);
}
