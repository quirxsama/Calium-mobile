import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';
import 'package:calium_stream/features/library/domain/usecases/get_favorites_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/get_history_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/toggle_favorite_usecase.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc({
    required this._getFavoritesUseCase,
    required this._getHistoryUseCase,
    required this._toggleFavoriteUseCase,
    required this._libraryRepository,
  })  :
        super(LibraryInitial()) {
    on<LoadLibraryRequested>(_onLoadLibrary);
    on<SyncRequested>(_onSync);
    on<ToggleFavoriteRequested>(_onToggleFavorite);
    on<ClearHistoryRequested>(_onClearHistory);
    on<RemoveHistoryItemRequested>(_onRemoveHistoryItem);
  }

  final GetFavoritesUseCase _getFavoritesUseCase;
  final GetHistoryUseCase _getHistoryUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final LibraryRepository _libraryRepository;

  Future<void> _onLoadLibrary(
    LoadLibraryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    emit(LibraryLoading());

    final favResult = await _getFavoritesUseCase();
    final histResult = await _getHistoryUseCase();

    List<FavoriteEntity> favorites = [];
    favResult.fold((_) {}, (f) => favorites = f);

    List<HistoryEntity> history = [];
    histResult.fold((_) {}, (h) => history = h);

    emit(LibraryLoaded(favorites: favorites, history: history));

    // Background sync with cloud
    _libraryRepository.syncWithCloud();
  }

  Future<void> _onSync(
    SyncRequested event,
    Emitter<LibraryState> emit,
  ) async {
    await _libraryRepository.syncWithCloud();
    add(LoadLibraryRequested());
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _toggleFavoriteUseCase(event.favorite);
    if (state is LibraryLoaded) {
      final current = state as LibraryLoaded;
      result.fold(
        (_) => null,
        (isNowFavorite) {
          if (isNowFavorite) {
            emit(current.copyWith(
              favorites: [event.favorite, ...current.favorites],
            ));
          } else {
            emit(current.copyWith(
              favorites: current.favorites
                  .where((f) => f.animeId != event.favorite.animeId)
                  .toList(),
            ));
          }
        },
      );
    }
  }

  Future<void> _onClearHistory(
    ClearHistoryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    await _libraryRepository.clearHistory();
    if (state is LibraryLoaded) {
      emit((state as LibraryLoaded).copyWith(history: []));
    }
  }

  Future<void> _onRemoveHistoryItem(
    RemoveHistoryItemRequested event,
    Emitter<LibraryState> emit,
  ) async {
    await _libraryRepository.removeHistoryItem(event.animeId);
    if (state is LibraryLoaded) {
      final current = state as LibraryLoaded;
      emit(current.copyWith(
        history: current.history
            .where((h) => h.animeId != event.animeId)
            .toList(),
      ));
    }
  }
}
