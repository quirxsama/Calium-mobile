import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';

class GetIntroSongParams extends Equatable {
  const GetIntroSongParams({
    required this.animeId,
    required this.episodeId,
    this.animeName,
    this.season,
    this.episode,
    this.introStart,
    this.streamUrl,
  });

  final String animeId;
  final String episodeId;
  final String? animeName;
  final int? season;
  final int? episode;
  final int? introStart;
  final String? streamUrl;

  @override
  List<Object?> get props => [
        animeId,
        episodeId,
        animeName,
        season,
        episode,
        introStart,
        streamUrl,
      ];
}

class GetIntroSongUseCase {
  const GetIntroSongUseCase({required this.repository});

  final PlayerRepository repository;

  Future<Either<Failure, IntroSongEntity?>> call(GetIntroSongParams params) {
    return repository.getIntroSong(
      animeId: params.animeId,
      episodeId: params.episodeId,
      animeName: params.animeName,
      season: params.season,
      episode: params.episode,
      introStart: params.introStart,
      streamUrl: params.streamUrl,
    );
  }
}
