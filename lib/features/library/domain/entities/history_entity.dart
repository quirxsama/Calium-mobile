import 'package:equatable/equatable.dart';

class HistoryEntity extends Equatable {
  const HistoryEntity({
    required this.animeId,
    required this.animeName,
    required this.posterUrl,
    required this.episodeId,
    required this.episodeName,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.progress,
    required this.duration,
    required this.updatedAt,
    this.positionMs = 0,
    this.episodeThumb = '',
  });

  final String animeId;
  final String animeName;
  final String posterUrl;
  final String episodeId;
  final String episodeName;
  final int seasonNumber;
  final int episodeNumber;
  final double progress;
  final int duration;
  final int positionMs;
  final DateTime updatedAt;
  final String episodeThumb;

  @override
  List<Object?> get props => [
        animeId,
        animeName,
        posterUrl,
        episodeId,
        episodeName,
        seasonNumber,
        episodeNumber,
        progress,
        duration,
        positionMs,
        updatedAt,
        episodeThumb,
      ];
}
