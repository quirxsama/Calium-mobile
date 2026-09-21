import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:calium_stream/core/error/failures.dart';

import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/home/data/models/anime_model.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/entities/home_feed_entity.dart';
import 'package:calium_stream/features/home/domain/usecases/get_home_feed_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this._getHomeFeed, required this._getAnimeDetailUseCase})
    : super(HomeInitial()) {
    on<LoadHomeFeedRequested>(_onLoadHomeFeed);
    on<RefreshHomeFeedRequested>(_onRefreshHomeFeed);
    on<UpdateHeroItemsRequested>(_onUpdateHeroItems);
  }

  final GetHomeFeedUseCase _getHomeFeed;
  final GetAnimeDetailUseCase _getAnimeDetailUseCase;

  // In-memory cache of enriched hero items (id -> enriched AnimeEntity)
  final Map<String, AnimeEntity> _heroCache = {};
  int _request = 0;

  Future<void> _onLoadHomeFeed(
    LoadHomeFeedRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefreshHomeFeed(
    RefreshHomeFeedRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<HomeState> emit) async {
    final request = ++_request;
    final previous = state;
    emit(
      previous is HomeLoaded
          ? previous.copyWith(isRefreshing: true, refreshError: '')
          : HomeLoading(),
    );
    try {
      final result = await _getHomeFeed();
      if (emit.isDone || request != _request) return;
      result.fold(
        (failure) => emit(
          previous is HomeLoaded
              ? previous.copyWith(
                  isRefreshing: false,
                  refreshError: 'Akış yenilenemedi. Gösterilen içerikleri kullanabilir veya yeniden deneyebilirsiniz.',
                )
              : HomeFailureState(
                  errorMessage: failure.message,
                  isNetwork: failure is NetworkFailure,
                ),
        ),
        (feed) {
          emit(_feedToLoaded(feed));
          _enrichHero(feed.trending, request);
        },
      );
    } catch (_) {
      if (emit.isDone || request != _request) return;
      emit(
        previous is HomeLoaded
            ? previous.copyWith(
                isRefreshing: false,
                refreshError: 'Akış yenilenemedi. Yeniden deneyin.',
              )
            : const HomeFailureState(
                errorMessage: 'Ana sayfa yüklenemedi. Yeniden deneyin.',
              ),
      );
    }
  }

  HomeLoaded _feedToLoaded(HomeFeedEntity feed) {
    return HomeLoaded(
      trending: feed.trending,
      topRanked: feed.topRanked,
      topAiring: feed.topAiring,
      seasonal: feed.seasonal,
      trDub: feed.trDub,
      action: feed.action,
      isekai: feed.isekai,
      movies: feed.movies,
      continueWatching: feed.continueWatching,
    );
  }

  /// Fetches detail (banner + logo) for hero items in parallel, then re-emits.
  Future<void> _enrichHero(List<AnimeEntity> trending, int request) async {
    if (trending.isEmpty) return;
    final targets = trending.take(6).toList();

    final results = await Future.wait(
      targets.map((anime) async {
        final cached = _heroCache[anime.id];
        if (cached != null) return cached;
        try {
          final res = await _getAnimeDetailUseCase(anime.id);
          return res.fold<AnimeEntity>((_) => anime, (detail) {
            final enriched = AnimeModel(
              id: anime.id,
              title: anime.title,
              posterUrl: anime.posterUrl,
              bannerUrl: detail.bannerUrl ?? anime.bannerUrl,
              logoUrl: detail.logoUrl ?? anime.logoUrl,
              rating: anime.rating ?? detail.rating,
              currentEpisode: anime.currentEpisode,
              genres: anime.genres.isNotEmpty ? anime.genres : detail.genres,
              status: anime.status,
              synopsis: detail.synopsis.isNotEmpty
                  ? detail.synopsis
                  : anime.synopsis,
              seasonNumber: anime.seasonNumber,
              episodeNumber: anime.episodeNumber,
              watchProgress: anime.watchProgress,
            );
            _heroCache[anime.id] = enriched;
            return enriched;
          });
        } catch (_) {
          return anime;
        }
      }),
    );

    if (!isClosed && request == _request) {
      add(UpdateHeroItemsRequested(trending: results));
    }
  }

  void _onUpdateHeroItems(
    UpdateHeroItemsRequested event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) return;
    if (!listEquals(
      current.trending.take(6).map((a) => a.id).toList(),
      event.trending.map((a) => a.id).toList(),
    )) {
      return;
    }
    emit(
      current.copyWith(
        trending: [...event.trending, ...current.trending.skip(6)],
      ),
    );
  }
}
