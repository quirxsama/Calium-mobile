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
  });

  final List<FavoriteEntity> favorites;
  final List<HistoryEntity> history;

  LibraryLoaded copyWith({
    List<FavoriteEntity>? favorites,
    List<HistoryEntity>? history,
  }) {
    return LibraryLoaded(
      favorites: favorites ?? this.favorites,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [favorites, history];
}

final class LibraryFailureState extends LibraryState {
  const LibraryFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
