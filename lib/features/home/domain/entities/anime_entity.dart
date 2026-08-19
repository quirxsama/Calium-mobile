import 'package:equatable/equatable.dart';

class AnimeEntity extends Equatable {
  const AnimeEntity({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.bannerUrl,
    this.rating,
    this.currentEpisode,
    this.genres = const [],
    this.status,
    this.synopsis,
    this.seasonNumber,
    this.episodeNumber,
    this.watchProgress,
  });

  final String id;
  final String title;
  final String posterUrl;
  final String? bannerUrl;
  final double? rating;
  final String? currentEpisode;
  final List<String> genres;
  final String? status;
  final String? synopsis;
  final int? seasonNumber;
  final int? episodeNumber;
  final double? watchProgress;

  @override
  List<Object?> get props => [
        id,
        title,
        posterUrl,
        bannerUrl,
        rating,
        currentEpisode,
        genres,
        status,
        synopsis,
        seasonNumber,
        episodeNumber,
        watchProgress,
      ];
}
