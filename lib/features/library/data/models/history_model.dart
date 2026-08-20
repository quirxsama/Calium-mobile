import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';

class HistoryModel extends HistoryEntity {
  const HistoryModel({
    required super.animeId,
    required super.animeName,
    required super.posterUrl,
    required super.episodeId,
    required super.episodeName,
    required super.seasonNumber,
    required super.episodeNumber,
    required super.progress,
    required super.duration,
    required super.updatedAt,
    super.episodeThumb = '',
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['updatedAt'];
    if (rawDate != null) {
      if (rawDate is num) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate.toInt());
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
    }

    final rawPoster = json['poster'] as String? ?? json['posterUrl'] as String? ?? '';

    return HistoryModel(
      animeId: (json['animeId'] ?? json['id'] ?? '').toString(),
      animeName: json['animeName'] as String? ?? json['name'] as String? ?? '',
      posterUrl: ImageUtils.cleanImageUrl(rawPoster),
      episodeId: (json['episodeId'] ?? '1').toString(),
      episodeName: json['episodeName'] as String? ?? 'Bölüm ${json['episodeNumber'] ?? 1}',
      seasonNumber: int.tryParse(json['seasonNumber']?.toString() ?? '1') ?? 1,
      episodeNumber: int.tryParse(json['episodeNumber']?.toString() ?? '1') ?? 1,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      updatedAt: parsedDate,
      episodeThumb: json['episodeThumb'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animeId': animeId,
      'animeName': animeName,
      'poster': posterUrl,
      'episodeId': episodeId,
      'episodeName': episodeName,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'progress': progress,
      'duration': duration,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      if (episodeThumb.isNotEmpty) 'episodeThumb': episodeThumb,
    };
  }
}
