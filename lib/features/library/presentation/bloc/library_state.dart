part of 'library_bloc.dart';

sealed class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

final class LibraryInitial extends LibraryState {}

final class LibraryLoading extends LibraryState {}

final class LibraryLoaded extends LibraryState {
  const LibraryLoaded({
    this.favorites = const [],
    this.history = const [],
    this.favoritesError = '',
    this.historyError = '',
    this.errorMessage = '',
    this.isRefreshing = false,
  });

  final List<FavoriteEntity> favorites;
  final List<HistoryEntity> history;
  final String favoritesError;
  final String historyError;
  final String errorMessage;
  final bool isRefreshing;

  LibraryLoaded copyWith({
    List<FavoriteEntity>? favorites,
    List<HistoryEntity>? history,
    String? favoritesError,
    String? historyError,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return LibraryLoaded(
      favorites: favorites ?? this.favorites,
      history: history ?? this.history,
      favoritesError: favoritesError ?? this.favoritesError,
      historyError: historyError ?? this.historyError,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    favorites,
    history,
    favoritesError,
    historyError,
    errorMessage,
    isRefreshing,
  ];
}

final class LibraryFailureState extends LibraryState {
  const LibraryFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
