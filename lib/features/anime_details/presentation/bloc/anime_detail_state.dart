part of 'anime_detail_bloc.dart';

sealed class AnimeDetailState extends Equatable {
  const AnimeDetailState();

  @override
  List<Object?> get props => [];
}

final class AnimeDetailInitial extends AnimeDetailState {}

final class AnimeDetailLoading extends AnimeDetailState {}

final class AnimeDetailLoaded extends AnimeDetailState {
  const AnimeDetailLoaded({
    required this.detail,
    required this.episodes,
    this.cast = const [],
    this.similarAnime = const [],
    this.selectedSeason = 1,
  });

  final AnimeDetailEntity detail;
  final List<EpisodeEntity> episodes;
  final List<CastEntity> cast;
  final List<AnimeEntity> similarAnime;
  final int selectedSeason;

  AnimeDetailLoaded copyWith({
    AnimeDetailEntity? detail,
    List<EpisodeEntity>? episodes,
    List<CastEntity>? cast,
    List<AnimeEntity>? similarAnime,
    int? selectedSeason,
  }) {
    return AnimeDetailLoaded(
      detail: detail ?? this.detail,
      episodes: episodes ?? this.episodes,
      cast: cast ?? this.cast,
      similarAnime: similarAnime ?? this.similarAnime,
      selectedSeason: selectedSeason ?? this.selectedSeason,
    );
  }

  @override
  List<Object?> get props => [
        detail,
        episodes,
        cast,
        similarAnime,
        selectedSeason,
      ];
}

final class AnimeDetailFailureState extends AnimeDetailState {
  const AnimeDetailFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
