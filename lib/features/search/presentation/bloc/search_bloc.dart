import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/search/domain/usecases/search_anime_usecase.dart';

part 'search_event.dart';
part 'search_state.dart';

EventTransformer<T> _debounce<T>(Duration duration) {
  return (events, mapper) {
    Timer? timer;
    final controller = StreamController<T>(sync: true);
    events.listen(
      (event) {
        timer?.cancel();
        // If event is an empty search query, emit immediately without delay
        if (event is SearchQueryChanged && event.query.isEmpty) {
          controller.add(event);
        } else {
          timer = Timer(duration, () {
            if (!controller.isClosed) controller.add(event);
          });
        }
      },
      onError: controller.addError,
      onDone: () {
        timer?.cancel();
        controller.close();
      },
    );
    return controller.stream.asyncExpand(mapper);
  };
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required this._searchAnimeUseCase})
      :
        super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<SearchFilterApplied>(_onSearchFilterApplied);
    on<SearchNextPageRequested>(_onSearchNextPageRequested);
  }

  final SearchAnimeUseCase _searchAnimeUseCase;

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());

    final result = await _searchAnimeUseCase(
      SearchAnimeParams(query: event.query, page: 1),
    );

    result.fold(
      (failure) => emit(SearchFailureState(message: failure.message)),
      (results) => emit(
        SearchLoaded(
          results: results,
          query: event.query,
          page: 1,
          hasMore: results.length >= 20,
        ),
      ),
    );
  }

  Future<void> _onSearchFilterApplied(
    SearchFilterApplied event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());

    final result = await _searchAnimeUseCase(
      SearchAnimeParams(
        query: '',
        page: 1,
        genreId: event.genreId,
        type: event.type,
      ),
    );

    result.fold(
      (failure) => emit(SearchFailureState(message: failure.message)),
      (results) => emit(
        SearchLoaded(
          results: results,
          query: '',
          selectedGenreId: event.genreId,
          selectedType: event.type,
          page: 1,
          hasMore: results.length >= 20,
        ),
      ),
    );
  }

  Future<void> _onSearchNextPageRequested(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    if (state is! SearchLoaded) return;
    final currentState = state as SearchLoaded;
    if (!currentState.hasMore) return;

    final nextPage = currentState.page + 1;
    final result = await _searchAnimeUseCase(
      SearchAnimeParams(
        query: currentState.query,
        page: nextPage,
        genreId: currentState.selectedGenreId,
        type: currentState.selectedType,
      ),
    );

    result.fold(
      (_) => emit(currentState.copyWith(hasMore: false)),
      (newResults) {
        if (newResults.isEmpty) {
          emit(currentState.copyWith(hasMore: false));
        } else {
          emit(
            currentState.copyWith(
              results: [...currentState.results, ...newResults],
              page: nextPage,
              hasMore: newResults.length >= 20,
            ),
          );
        }
      },
    );
  }
}
