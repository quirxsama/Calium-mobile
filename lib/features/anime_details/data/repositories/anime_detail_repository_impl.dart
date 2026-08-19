import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/anime_details/data/datasources/anime_detail_remote_datasource.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';

class AnimeDetailRepositoryImpl implements AnimeDetailRepository {
  const AnimeDetailRepositoryImpl({
    required AnimeDetailRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AnimeDetailRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, AnimeDetailEntity>> getAnimeDetail(String animeId) async {
    try {
      final detail = await _remoteDataSource.getAnimeDetail(animeId);
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EpisodeEntity>>> getEpisodes({
    required String animeId,
    required int season,
  }) async {
    try {
      final episodes = await _remoteDataSource.getEpisodes(
        animeId: animeId,
        season: season,
      );
      return Right(episodes);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CastEntity>>> getCast(String tmdbId) async {
    try {
      final cast = await _remoteDataSource.getCast(tmdbId);
      return Right(cast);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnimeEntity>>> getSimilarAnime(String animeId) async {
    try {
      final similar = await _remoteDataSource.getSimilarAnime(animeId);
      return Right(similar);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
