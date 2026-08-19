part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.trending,
    required this.topAiring,
    required this.seasonal,
    this.topRanked = const [],
    this.trDub = const [],
    this.action = const [],
    this.isekai = const [],
    this.movies = const [],
    this.continueWatching = const [],
  });

  final List<AnimeEntity> trending;
  final List<AnimeEntity> topAiring;
  final List<AnimeEntity> seasonal;
  final List<AnimeEntity> topRanked;
  final List<AnimeEntity> trDub;
  final List<AnimeEntity> action;
  final List<AnimeEntity> isekai;
  final List<AnimeEntity> movies;
  final List<AnimeEntity> continueWatching;

  @override
  List<Object?> get props => [
        trending,
        topAiring,
        seasonal,
        topRanked,
        trDub,
        action,
        isekai,
        movies,
        continueWatching,
      ];
}

final class HomeFailureState extends HomeState {
  const HomeFailureState({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
