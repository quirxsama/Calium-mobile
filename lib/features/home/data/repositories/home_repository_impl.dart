import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/data/datasources/home_remote_datasource.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/entities/home_feed_entity.dart';
import 'package:calium_stream/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({required this._remoteDataSource});

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, HomeFeedEntity>> getHomeFeed() async {
    try {
      final results = await Future.wait([
        _remoteDataSource.getTopAnime(page: 1),
        _remoteDataSource.getLatestEpisodes(page: 1),
        _remoteDataSource.getSeasonalAnime(page: 1),
        _remoteDataSource.getTrDubAnime(page: 1),
        _remoteDataSource.getActionAnime(page: 1),
        _remoteDataSource.getIsekaiAnime(page: 1),
        _remoteDataSource.getMovieAnime(page: 1),
      ]);

      final topAnime = results[0];
      final topAiring = results[1];
      final seasonal = results[2];
      final trDub = results[3];
      final action = results[4];
      final isekai = results[5];
      final movies = results[6];

      // Trending hero takes the top 6
      final trending = (topAnime.isNotEmpty ? topAnime : topAiring).take(6).toList();
      // Top Ranked 10
      final topRanked = (topAnime.isNotEmpty ? topAnime : topAiring).take(10).toList();

      return Right(
        HomeFeedEntity(
          trending: trending,
          topRanked: topRanked,
          topAiring: topAiring,
          seasonal: seasonal,
          trDub: trDub,
          action: action,
          isekai: isekai,
          movies: movies,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnimeEntity>>> getLatestEpisodes({int page = 1}) async {
    try {
      final episodes = await _remoteDataSource.getLatestEpisodes(page: page);
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
  Future<Either<Failure, List<AnimeEntity>>> getTopAnime({int page = 1}) async {
    try {
      final animes = await _remoteDataSource.getTopAnime(page: page);
      return Right(animes);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
