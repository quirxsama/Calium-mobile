import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class AnimeModel extends AnimeEntity {
  const AnimeModel({
    required super.id,
    required super.title,
    required super.posterUrl,
    super.bannerUrl,
    super.rating,
    super.currentEpisode,
    super.genres = const [],
    super.status,
    super.synopsis,
    super.seasonNumber,
    super.episodeNumber,
    super.watchProgress,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    // Handle rating parsing from num or string
    double? parsedRating;
    final rawRating = json['imdb_point'] ?? json['rating'] ?? json['score'] ?? json['malRating'];
    if (rawRating != null) {
      if (rawRating is num) {
        parsedRating = rawRating.toDouble();
      } else if (rawRating is String) {
        parsedRating = double.tryParse(rawRating);
      }
    }

    // Handle genres parsing
    List<String> parsedGenres = [];
    if (json['genre'] is List) {
      parsedGenres = (json['genre'] as List).map((g) {
        if (g is Map) return (g['name'] ?? '').toString();
        return g.toString();
      }).where((g) => g.isNotEmpty).toList();
    } else if (json['genres'] is List) {
      parsedGenres = (json['genres'] as List).map((g) => g.toString()).toList();
    }

    // Handle poster URL
    String poster = json['poster'] as String? ?? json['posterUrl'] as String? ?? json['image'] as String? ?? '';
    // Handle banner URL
    String? banner = json['banner'] as String? ?? json['details_banner'] as String? ?? json['bannerUrl'] as String?;

    // Handle episode / season info
    String? epBadge;
    int? sNum;
    int? epNum;
    if (json['episode'] != null) {
      final epVal = json['episode'].toString();
      final seasonVal = json['season']?.toString() ?? '1';
      epBadge = 'S$seasonVal:B$epVal';
      epNum = int.tryParse(epVal);
      sNum = int.tryParse(seasonVal);
    } else if (json['currentEpisode'] != null) {
      epBadge = json['currentEpisode'].toString();
    }

    return AnimeModel(
      id: (json['ID'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      title: json['name'] as String? ?? json['title'] as String? ?? '',
      posterUrl: ImageUtils.cleanImageUrl(poster),
      bannerUrl: banner != null ? ImageUtils.cleanImageUrl(banner) : null,
      rating: parsedRating,
      currentEpisode: epBadge,
      genres: parsedGenres,
      status: json['status'] as String?,
      synopsis: json['overview'] as String? ?? json['synopsis'] as String?,
      seasonNumber: sNum,
      episodeNumber: epNum,
      watchProgress: (json['watchProgress'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': title,
      'poster': posterUrl,
      'banner': bannerUrl,
      'imdb_point': rating,
      'currentEpisode': currentEpisode,
      'genres': genres,
      'status': status,
      'overview': synopsis,
      'season': seasonNumber,
      'episode': episodeNumber,
      'watchProgress': watchProgress,
    };
  }
}
