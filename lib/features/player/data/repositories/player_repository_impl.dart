import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/services/account_session.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/data/datasources/player_remote_datasource.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  const PlayerRepositoryImpl({
    required this._remoteDataSource,
  });

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
  Future<Either<Failure, IntroSongEntity?>> getIntroSong({
    required String animeId,
    required String episodeId,
    String? animeName,
    int? season,
    int? episode,
    int? introStart,
    String? streamUrl,
  }) async {
    try {
      final song = await _remoteDataSource.getIntroSong(
        animeId: animeId,
        episodeId: episodeId,
        animeName: animeName,
        season: season,
        episode: episode,
        introStart: introStart,
        streamUrl: streamUrl,
      );
      return Right(song);
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
    String episodeThumb = '',
  }) async {
    try {
      final box = AccountSession.instance.box('history');
      final existing = box.get(animeId);
      final existingMap = existing is Map ? existing : null;

      // Guard against corrupting saved progress during startup (e.g. 0-3s positions)
      if (position.inSeconds <= 3 && existingMap != null) {
        final existingPos = (existingMap['positionMs'] as num?)?.toInt() ?? 0;
        final existingEp = (existingMap['episodeNumber'] as num?)?.toInt() ?? 1;
        final existingSeason = (existingMap['seasonNumber'] as num?)?.toInt() ?? 1;
        if (existingEp == episodeNumber && existingSeason == seasonNumber && existingPos > 5000) {
          return;
        }
      }

      final progress = duration.inMilliseconds > 0
          ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
          : 0.0;
      final effectivePoster = posterUrl.isNotEmpty
          ? posterUrl
          : (existingMap?['poster']?.toString() ?? '');
      final effectiveTitle = animeTitle.isNotEmpty
          ? animeTitle
          : (existingMap?['animeName']?.toString() ?? '');
      final effectiveThumb = episodeThumb.isNotEmpty
          ? episodeThumb
          : (existingMap?['episodeThumb']?.toString() ?? '');

      final posMs = position.inMilliseconds;
      final posSec = position.inSeconds;

      final deletedBox = AccountSession.instance.box('history_deleted');
      await box.put(animeId, {
        'revision': ((existingMap?['revision'] as num?)?.toInt() ?? 0) + 1,
        'animeId': animeId,
        'animeName': effectiveTitle,
        'poster': effectivePoster,
        'episodeThumb': effectiveThumb,
        'episodeId': episodeId,
        'episodeName': episodeTitle,
        'seasonNumber': seasonNumber,
        'episodeNumber': episodeNumber,
        'progress': progress,
        'positionMs': posMs,
        'currentTime': posSec,
        'time': posSec,
        'position': posSec,
        'duration': duration.inSeconds,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'dirty': true,
      });

      // Watching again revives a previously removed history item
      try {
        await deletedBox.delete(animeId);
      } catch (_) {}
    } catch (_) {
      // Local history save is best-effort
    }
  }
}
