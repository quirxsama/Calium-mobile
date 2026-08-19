import 'package:equatable/equatable.dart';

class EpisodeEntity extends Equatable {
  const EpisodeEntity({
    required this.id,
    required this.animeId,
    required this.episodeNumber,
    required this.seasonNumber,
    this.title,
    this.thumbnailUrl,
    this.duration,
    this.isFiller = false,
    this.releaseDate,
    this.watchProgress,
    this.overview,
  });

  final String id;
  final String animeId;
  final int episodeNumber;
  final int seasonNumber;
  final String? title;
  final String? thumbnailUrl;
  final int? duration;
  final bool isFiller;
  final String? releaseDate;
  final double? watchProgress;
  final String? overview;

  @override
  List<Object?> get props => [
        id,
        animeId,
        episodeNumber,
        seasonNumber,
        title,
        thumbnailUrl,
        duration,
        isFiller,
        releaseDate,
        watchProgress,
        overview,
      ];
}
