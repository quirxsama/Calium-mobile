part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

final class LoadLibraryRequested extends LibraryEvent {}

final class SyncRequested extends LibraryEvent {}

final class ToggleFavoriteRequested extends LibraryEvent {
  const ToggleFavoriteRequested({required this.favorite});

  final FavoriteEntity favorite;

  @override
  List<Object?> get props => [favorite];
}

final class ClearHistoryRequested extends LibraryEvent {}
