part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class LoadHomeFeedRequested extends HomeEvent {}

final class RefreshHomeFeedRequested extends HomeEvent {}

final class UpdateHeroItemsRequested extends HomeEvent {
  const UpdateHeroItemsRequested({required this.trending});

  final List<AnimeEntity> trending;

  @override
  List<Object?> get props => [trending];
}
