import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';

class VideoSourceModel extends EpisodeSourceEntity {
  const VideoSourceModel({
    required super.audioGroups,
    required super.subtitles,
    super.introStart,
    super.introEnd,
    super.nextEpisodeTime,
    super.nextSeason,
    super.nextEpisode,
  });

  static int? _parseTimeToSeconds(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      final parts = value.trim().split(':');
      if (parts.length == 3) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return h * 3600 + m * 60 + s;
      } else if (parts.length == 2) {
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return m * 60 + s;
      } else {
        return int.tryParse(value);
      }
    }
    return null;
  }

  factory VideoSourceModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Subtitles
    List<SubtitleTrackEntity> subtitles = [];
    if (json['subtitles'] is List) {
      for (final item in json['subtitles'] as List) {
        if (item is Map<String, dynamic>) {
          var link = item['link'] as String? ??
              item['url'] as String? ??
              item['src'] as String? ??
              item['file'] as String? ??
              '';
          if (link.isNotEmpty) {
            if (link.startsWith('//')) {
              link = 'https:$link';
            } else if (link.startsWith('/')) {
              link = 'https://calium.fun$link';
            }
            subtitles.add(
              SubtitleTrackEntity(
                name: item['name'] as String? ?? item['label'] as String? ?? item['language'] as String? ?? 'Türkçe',
                group: item['group'] as String? ?? item['lang'] as String? ?? 'tr',
                url: link,
              ),
            );
          }
        }
      }
    }

    // 2. Parse Audio Groups (Dubbing / Original) and stream qualities
    List<AudioGroupEntity> audioGroups = [];
    if (json['groups'] is List) {
      for (final groupItem in json['groups'] as List) {
        if (groupItem is Map<String, dynamic>) {
          final groupName = groupItem['name'] as String? ?? 'Orijinal';
          final groupKey = groupItem['group'] as String? ?? 'original';

          List<VideoStreamItemEntity> streams = [];
          if (groupItem['items'] is List) {
            for (final item in groupItem['items'] as List) {
              if (item is Map<String, dynamic>) {
                final link = item['link'] as String? ?? '';
                final q = item['quality']?.toString() ?? '1080';
                final qualityLabel = q.contains('p') ? q : '${q}p';

                if (link.isNotEmpty) {
                  streams.add(
                    VideoStreamItemEntity(
                      quality: qualityLabel,
                      url: link,
                      type: item['type'] as String? ?? 'mp4',
                    ),
                  );
                }
              }
            }
          }

          if (streams.isNotEmpty) {
            // Sort streams by quality descending (1080p -> 720p -> 480p)
            streams.sort((a, b) {
              final aNum = int.tryParse(a.quality.replaceAll('p', '')) ?? 0;
              final bNum = int.tryParse(b.quality.replaceAll('p', '')) ?? 0;
              return bNum.compareTo(aNum);
            });

            audioGroups.add(
              AudioGroupEntity(
                name: groupName,
                group: groupKey,
                streams: streams,
              ),
            );
          }
        }
      }
    }

    // 3. Parse Opening, Next Episode info
    int? introStart;
    int? introEnd;
    int? nextEpisodeTime;
    int? nextSeason;
    int? nextEpisode;

    final content = json['content'];
    if (content is Map<String, dynamic>) {
      final opening = content['opening'];
      if (opening is Map<String, dynamic>) {
        introStart = _parseTimeToSeconds(opening['start']);
        introEnd = _parseTimeToSeconds(opening['end']);
      }
      nextEpisodeTime = _parseTimeToSeconds(content['next_episode']);

      final nextEpData = content['next_episode_data'];
      if (nextEpData is Map<String, dynamic>) {
        nextSeason = int.tryParse(nextEpData['season']?.toString() ?? '');
        nextEpisode = int.tryParse(nextEpData['episode']?.toString() ?? '');
      }
    }

    return VideoSourceModel(
      audioGroups: audioGroups,
      subtitles: subtitles,
      introStart: introStart,
      introEnd: introEnd,
      nextEpisodeTime: nextEpisodeTime,
      nextSeason: nextSeason,
      nextEpisode: nextEpisode,
    );
  }
}
