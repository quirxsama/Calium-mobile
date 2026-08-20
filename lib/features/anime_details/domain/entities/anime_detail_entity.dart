import 'package:equatable/equatable.dart';

class SeasonEntity extends Equatable {
  const SeasonEntity({
    required this.seasonNumber,
    required this.name,
    this.episodeCount = 0,
  });

  final int seasonNumber;
  final String name;
  final int episodeCount;

  @override
  List<Object?> get props => [seasonNumber, name, episodeCount];
}

class AnimeDetailEntity extends Equatable {
  const AnimeDetailEntity({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.originalTitle,
    this.bannerUrl,
    this.logoUrl,
    this.synopsis = '',
    this.rating,
    this.totalEpisodes,
    this.status,
    this.type,
    this.studio,
    this.year,
    this.genres = const [],
    this.seasons = const [],
    this.tmdbId,
  });

  final String id;
  final String title;
  final String? originalTitle;
  final String posterUrl;
  final String? bannerUrl;
  final String? logoUrl;
  final String synopsis;
  final double? rating;
  final int? totalEpisodes;
  final String? status;
  final String? type;
  final String? studio;
  final int? year;
  final List<String> genres;
  final List<SeasonEntity> seasons;
  final int? tmdbId;

  @override
  List<Object?> get props => [
        id,
        title,
        originalTitle,
        posterUrl,
        bannerUrl,
        logoUrl,
        synopsis,
        rating,
        totalEpisodes,
        status,
        type,
        studio,
        year,
        genres,
        seasons,
        tmdbId,
      ];
}
