part of 'anime_detail_bloc.dart';

sealed class AnimeDetailEvent extends Equatable {
  const AnimeDetailEvent();

  @override
  List<Object?> get props => [];
}

final class LoadAnimeDetailRequested extends AnimeDetailEvent {
  const LoadAnimeDetailRequested({required this.animeId});

  final String animeId;

  @override
  List<Object?> get props => [animeId];
}

final class SeasonChangedEvent extends AnimeDetailEvent {
  const SeasonChangedEvent({
    required this.animeId,
    required this.seasonNumber,
  });

  final String animeId;
  final int seasonNumber;

  @override
  List<Object?> get props => [animeId, seasonNumber];
}
