import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';

class EpisodeModel extends EpisodeEntity {
  const EpisodeModel({
    required super.id,
    required super.animeId,
    required super.episodeNumber,
    required super.seasonNumber,
    super.title,
    super.thumbnailUrl,
    super.duration,
    super.isFiller = false,
    super.releaseDate,
    super.watchProgress,
    super.overview,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json, {String animeId = '', int seasonNumber = 1}) {
    final epNum = int.tryParse(json['number']?.toString() ?? json['episode']?.toString() ?? '1') ?? 1;
    final sNum = int.tryParse(json['season']?.toString() ?? seasonNumber.toString()) ?? seasonNumber;

    bool isFillerVal = false;
    final filler = json['filler'] ?? json['is_filler'] ?? json['isFiller'];
    if (filler is bool) {
      isFillerVal = filler;
    } else if (filler is num) {
      isFillerVal = filler == 1;
    } else if (filler is String) {
      isFillerVal = ['true', '1', 'yes', 'evet'].contains(filler.toLowerCase());
    }

    final rawThumb = json['banner_link'] as String? ??
        json['thumbnail'] as String? ??
        json['image'] as String? ??
        json['poster'] as String? ??
        json['still_path'] as String? ??
        json['backdrop_path'] as String? ??
        json['cover'] as String?;

    return EpisodeModel(
      id: (json['ID'] ?? json['id'] ?? epNum).toString(),
      animeId: animeId,
      episodeNumber: epNum,
      seasonNumber: sNum,
      title: json['name'] as String? ?? json['title'] as String? ?? 'Bölüm $epNum',
      thumbnailUrl: ImageUtils.cleanImageUrl(rawThumb),
      duration: json['duration'] is num ? (json['duration'] as num).toInt() : null,
      isFiller: isFillerVal,
      releaseDate: json['release_date']?.toString(),
      watchProgress: (json['watchProgress'] as num?)?.toDouble(),
      overview: json['overview'] as String? ?? json['description'] as String? ?? json['synopsis'] as String?,
    );
  }
}
