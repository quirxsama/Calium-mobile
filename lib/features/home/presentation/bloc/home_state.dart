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
    this.isRefreshing = false,
    this.refreshError = '',
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
  final bool isRefreshing;
  final String refreshError;

  HomeLoaded copyWith({
    bool? isRefreshing,
    String? refreshError,
    List<AnimeEntity>? trending,
  }) => HomeLoaded(
    trending: trending ?? this.trending,
    topAiring: topAiring,
    seasonal: seasonal,
    topRanked: topRanked,
    trDub: trDub,
    action: action,
    isekai: isekai,
    movies: movies,
    continueWatching: continueWatching,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    refreshError: refreshError ?? this.refreshError,
  );

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
    isRefreshing,
    refreshError,
  ];
}

final class HomeFailureState extends HomeState {
  const HomeFailureState({required this.errorMessage, this.isNetwork = false});

  final String errorMessage;
  final bool isNetwork;

  @override
  List<Object?> get props => [errorMessage, isNetwork];
}
