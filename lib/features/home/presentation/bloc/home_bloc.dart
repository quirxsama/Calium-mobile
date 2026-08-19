import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/usecases/get_home_feed_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetHomeFeedUseCase getHomeFeed})
      : _getHomeFeed = getHomeFeed,
        super(HomeInitial()) {
    on<LoadHomeFeedRequested>(_onLoadHomeFeed);
    on<RefreshHomeFeedRequested>(_onRefreshHomeFeed);
  }

  final GetHomeFeedUseCase _getHomeFeed;

  Future<void> _onLoadHomeFeed(
    LoadHomeFeedRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    final result = await _getHomeFeed();
    result.fold(
      (failure) => emit(HomeFailureState(errorMessage: failure.message)),
      (feed) => emit(
        HomeLoaded(
          trending: feed.trending,
          topRanked: feed.topRanked,
          topAiring: feed.topAiring,
          seasonal: feed.seasonal,
          trDub: feed.trDub,
          action: feed.action,
          isekai: feed.isekai,
          movies: feed.movies,
          continueWatching: feed.continueWatching,
        ),
      ),
    );
  }

  Future<void> _onRefreshHomeFeed(
    RefreshHomeFeedRequested event,
    Emitter<HomeState> emit,
  ) async {
    final result = await _getHomeFeed();
    result.fold(
      (failure) => emit(HomeFailureState(errorMessage: failure.message)),
      (feed) => emit(
        HomeLoaded(
          trending: feed.trending,
          topRanked: feed.topRanked,
          topAiring: feed.topAiring,
          seasonal: feed.seasonal,
          trDub: feed.trDub,
          action: feed.action,
          isekai: feed.isekai,
          movies: feed.movies,
          continueWatching: feed.continueWatching,
        ),
      ),
    );
  }
}
