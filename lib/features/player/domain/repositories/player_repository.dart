import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';

abstract class PlayerRepository {
  Future<Either<Failure, EpisodeSourceEntity>> getVideoSources({
    required String animeId,
    required int season,
    required int episode,
  });

  Future<Either<Failure, IntroSongEntity?>> getIntroSong({
    required String animeId,
    required String episodeId,
    String? animeName,
    int? season,
    int? episode,
    int? introStart,
    String? streamUrl,
  });

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
  });
}
