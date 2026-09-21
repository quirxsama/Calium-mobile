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
  }) : super(LibraryInitial()) {
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
  int _loadRequest = 0;

  Future<void> _onLoadLibrary(
    LoadLibraryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final request = ++_loadRequest;
    final previous = state is LibraryLoaded ? state as LibraryLoaded : null;
    emit(
      previous?.copyWith(isRefreshing: true, errorMessage: '') ??
          LibraryLoading(),
    );
    try {
      final favResult = await _getFavoritesUseCase();
      final histResult = await _getHistoryUseCase();
      if (emit.isDone || request != _loadRequest) return;
      var favoritesError = '';
      var historyError = '';
      final favorites = favResult.fold((failure) {
        favoritesError = 'Favoriler alınamadı. Yeniden deneyin.';
        return previous?.favorites ?? <FavoriteEntity>[];
      }, (items) => items);
      final history = histResult.fold((failure) {
        historyError = 'İzleme geçmişi alınamadı. Yeniden deneyin.';
        return previous?.history ?? <HistoryEntity>[];
      }, (items) => items);
      emit(
        LibraryLoaded(
          favorites: favorites,
          history: history,
          favoritesError: favoritesError,
          historyError: historyError,
        ),
      );
    } catch (_) {
      if (!emit.isDone && request == _loadRequest) {
        emit(
          previous?.copyWith(
                isRefreshing: false,
                favoritesError: 'Kitaplık yenilenemedi. Yeniden deneyin.',
                historyError: 'Kitaplık yenilenemedi. Yeniden deneyin.',
              ) ??
              const LibraryFailureState(
                message: 'Kitaplık yüklenemedi. Yeniden deneyin.',
              ),
        );
      }
    }
  }

  Future<void> _onSync(SyncRequested event, Emitter<LibraryState> emit) async {
    final result = await _libraryRepository.syncWithCloud();
    if (emit.isDone) return;
    result.fold(
      (failure) =>
          _showFailure('Eşitleme tamamlanamadı. Yeniden deneyin.', emit),
      (_) => add(LoadLibraryRequested()),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _toggleFavoriteUseCase(event.favorite);
    if (emit.isDone) return;
    if (state is! LibraryLoaded) {
      add(LoadLibraryRequested());
      return;
    }
    final current = state as LibraryLoaded;
    result.fold(
      (_) => _showFailure('Favoriler güncellenemedi. Yeniden deneyin.', emit),
      (isNowFavorite) {
        if (isNowFavorite) {
          emit(
            current.copyWith(
              favorites: [event.favorite, ...current.favorites],
              errorMessage: '',
            ),
          );
        } else {
          emit(
            current.copyWith(
              favorites: current.favorites
                  .where((f) => f.animeId != event.favorite.animeId)
                  .toList(),
              errorMessage: '',
            ),
          );
        }
      },
    );
  }

  Future<void> _onClearHistory(
    ClearHistoryRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _libraryRepository.clearHistory();
    if (emit.isDone) return;
    if (result.isLeft()) {
      _showFailure('Geçmiş silinemedi. Yeniden deneyin.', emit);
      return;
    }
    if (state is LibraryLoaded) {
      emit((state as LibraryLoaded).copyWith(history: [], errorMessage: ''));
    }
  }

  Future<void> _onRemoveHistoryItem(
    RemoveHistoryItemRequested event,
    Emitter<LibraryState> emit,
  ) async {
    final result = await _libraryRepository.removeHistoryItem(event.animeId);
    if (emit.isDone) return;
    if (result.isLeft()) {
      _showFailure('Bölüm geçmişten kaldırılamadı. Yeniden deneyin.', emit);
      return;
    }
    if (state is LibraryLoaded) {
      final current = state as LibraryLoaded;
      emit(
        current.copyWith(
          history: current.history
              .where((h) => h.animeId != event.animeId)
              .toList(),
          errorMessage: '',
        ),
      );
    }
  }

  void _showFailure(String message, Emitter<LibraryState> emit) {
    final current = state;
    if (current is LibraryLoaded) {
      emit(current.copyWith(errorMessage: message));
    } else {
      emit(LibraryFailureState(message: message));
    }
  }
}
