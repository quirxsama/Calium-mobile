import 'package:equatable/equatable.dart';

class SubtitleTrackEntity extends Equatable {
  const SubtitleTrackEntity({
    required this.name,
    required this.group,
    required this.url,
  });

  final String name;
  final String group;
  final String url;

  @override
  List<Object?> get props => [name, group, url];
}

class VideoStreamItemEntity extends Equatable {
  const VideoStreamItemEntity({
    required this.quality,
    required this.url,
    this.type = 'mp4',
  });

  final String quality; // e.g. "1080p", "720p", "480p"
  final String url;
  final String type;

  @override
  List<Object?> get props => [quality, url, type];
}

class AudioGroupEntity extends Equatable {
  const AudioGroupEntity({
    required this.name, // e.g. "Japonca (Orijinal)", "Türkçe Dublaj"
    required this.group, // e.g. "original", "trdub", "endub"
    required this.streams,
  });

  final String name;
  final String group;
  final List<VideoStreamItemEntity> streams;

  @override
  List<Object?> get props => [name, group, streams];
}

class EpisodeSourceEntity extends Equatable {
  const EpisodeSourceEntity({
    required this.audioGroups,
    required this.subtitles,
    this.introStart,
    this.introEnd,
    this.nextEpisodeTime,
    this.nextSeason,
    this.nextEpisode,
  });

  final List<AudioGroupEntity> audioGroups;
  final List<SubtitleTrackEntity> subtitles;
  final int? introStart; // in seconds
  final int? introEnd; // in seconds
  final int? nextEpisodeTime; // in seconds
  final int? nextSeason;
  final int? nextEpisode;

  @override
  List<Object?> get props => [
        audioGroups,
        subtitles,
        introStart,
        introEnd,
        nextEpisodeTime,
        nextSeason,
        nextEpisode,
      ];
}

// Backward compatibility typedef for existing DI container
typedef VideoSourceEntity = EpisodeSourceEntity;
