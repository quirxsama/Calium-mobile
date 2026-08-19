import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/data/datasources/player_remote_datasource.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl({
    required PlayerRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PlayerRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, EpisodeSourceEntity>> getVideoSources({
    required String animeId,
    required int season,
    required int episode,
  }) async {
    try {
      final sources = await _remoteDataSource.getVideoSources(
        animeId: animeId,
        season: season,
        episode: episode,
      );
      return Right(sources);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> saveWatchProgress({
    required String animeId,
    required String animeTitle,
    required String posterUrl,
    required String episodeId,
    required String episodeTitle,
    required int seasonNumber,
    required int episodeNumber,
    required Duration position,
    required Duration duration,
  }) async {
    try {
      final box = Hive.box('history');
      final progress = duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;

      await box.put(animeId, {
        'animeId': animeId,
        'animeName': animeTitle,
        'poster': posterUrl,
        'episodeId': episodeId,
        'episodeName': episodeTitle,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'progress': progress,
        'positionMs': position.inMilliseconds,
        'duration': duration.inSeconds,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Local history save is best-effort
    }
  }
}
