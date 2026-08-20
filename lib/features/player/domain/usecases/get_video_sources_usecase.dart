import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';

class GetVideoSourcesParams extends Equatable {
  const GetVideoSourcesParams({
    required this.animeId,
    required this.season,
    required this.episode,
  });

  final String animeId;
  final int season;
  final int episode;

  @override
  List<Object?> get props => [animeId, season, episode];
}

class GetVideoSourcesUseCase {
  const GetVideoSourcesUseCase({required this._repository});

  final PlayerRepository _repository;

  Future<Either<Failure, EpisodeSourceEntity>> call(
    GetVideoSourcesParams params,
  ) {
    return _repository.getVideoSources(
      animeId: params.animeId,
      season: params.season,
      episode: params.episode,
    );
  }
}
