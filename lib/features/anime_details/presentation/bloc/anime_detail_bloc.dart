import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_cast_usecase.dart';

part 'anime_detail_event.dart';
part 'anime_detail_state.dart';

class AnimeDetailBloc extends Bloc<AnimeDetailEvent, AnimeDetailState> {
  AnimeDetailBloc({
    required this._getAnimeDetailUseCase,
    required this._getCastUseCase,
    required this._repository,
  })  :
        super(AnimeDetailInitial()) {
    on<LoadAnimeDetailRequested>(_onLoadAnimeDetail);
    on<SeasonChangedEvent>(_onSeasonChanged);
  }

  final GetAnimeDetailUseCase _getAnimeDetailUseCase;
  final GetCastUseCase _getCastUseCase;
  final AnimeDetailRepository _repository;

  Future<void> _onLoadAnimeDetail(
    LoadAnimeDetailRequested event,
    Emitter<AnimeDetailState> emit,
  ) async {
    emit(AnimeDetailLoading());
    final result = await _getAnimeDetailUseCase(event.animeId);

    await result.fold(
      (failure) async => emit(AnimeDetailFailureState(message: failure.message)),
      (detail) async {
        final initialSeason = detail.seasons.isNotEmpty
            ? detail.seasons.first.seasonNumber
            : 1;

        // Fetch episodes, cast, similar in parallel
        final episodesResult = await _repository.getEpisodes(
          animeId: event.animeId,
          season: initialSeason,
        );

        List<EpisodeEntity> episodes = [];
        episodesResult.fold((_) {}, (eps) => episodes = eps);

        List<CastEntity> cast = [];
        if (detail.tmdbId != null) {
          final castResult = await _getCastUseCase(detail.tmdbId.toString());
          castResult.fold((_) {}, (c) => cast = c);
        }

        List<AnimeEntity> similar = [];
        final similarResult = await _repository.getSimilarAnime(event.animeId);
        similarResult.fold((_) {}, (s) => similar = s);

        emit(
          AnimeDetailLoaded(
            detail: detail,
            episodes: episodes,
            cast: cast,
            similarAnime: similar,
            selectedSeason: initialSeason,
          ),
        );
      },
    );
  }

  Future<void> _onSeasonChanged(
    SeasonChangedEvent event,
    Emitter<AnimeDetailState> emit,
  ) async {
    if (state is! AnimeDetailLoaded) return;
    final currentState = state as AnimeDetailLoaded;

    final episodesResult = await _repository.getEpisodes(
      animeId: event.animeId,
      season: event.seasonNumber,
    );

    episodesResult.fold(
      (_) {},
      (episodes) {
        emit(
          currentState.copyWith(
            episodes: episodes,
            selectedSeason: event.seasonNumber,
          ),
        );
      },
    );
  }
}
