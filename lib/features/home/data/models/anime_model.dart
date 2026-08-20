import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class AnimeModel extends AnimeEntity {
  const AnimeModel({
    required super.id,
    required super.title,
    required super.posterUrl,
    super.bannerUrl,
    super.logoUrl,
    super.rating,
    super.currentEpisode,
    super.genres = const [],
    super.status,
    super.synopsis,
    super.seasonNumber,
    super.episodeNumber,
    super.watchProgress,
  });

  AnimeModel copyWith({
    String? bannerUrl,
    String? logoUrl,
    double? rating,
    String? synopsis,
    List<String>? genres,
    bool clearBanner = false,
  }) {
    return AnimeModel(
      id: id,
      title: title,
      posterUrl: posterUrl,
      bannerUrl: clearBanner ? null : (bannerUrl ?? this.bannerUrl),
      logoUrl: logoUrl ?? this.logoUrl,
      rating: rating ?? this.rating,
      currentEpisode: currentEpisode,
      genres: genres ?? this.genres,
      status: status,
      synopsis: synopsis ?? this.synopsis,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      watchProgress: watchProgress,
    );
  }

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    final inner = (json['content'] is Map<String, dynamic>)
        ? json['content'] as Map<String, dynamic>
        : (json['anime'] is Map<String, dynamic>)
            ? json['anime'] as Map<String, dynamic>
            : json;

    // Handle rating parsing from num or string
    double? parsedRating;
    final rawRating = inner['imdb_point'] ?? inner['rating'] ?? inner['score'] ?? inner['malRating'] ?? json['imdb_point'] ?? json['rating'];
    if (rawRating != null) {
      if (rawRating is num) {
        parsedRating = rawRating.toDouble();
      } else if (rawRating is String) {
        parsedRating = double.tryParse(rawRating);
      }
    }

    // Handle genres parsing
    List<String> parsedGenres = [];
    final rawGenres = inner['genre'] ?? inner['genres'] ?? json['genre'] ?? json['genres'];
    if (rawGenres is List) {
      parsedGenres = rawGenres.map((g) {
        if (g is Map) return (g['name'] ?? '').toString();
        return g.toString();
      }).where((g) => g.isNotEmpty).toList();
    }

    // Handle poster URL
    String poster = inner['poster'] as String? ??
        inner['posterUrl'] as String? ??
        inner['cover'] as String? ??
        inner['image'] as String? ??
        inner['details_banner'] as String? ??
        json['poster'] as String? ??
        json['posterUrl'] as String? ??
        json['cover'] as String? ??
        json['image'] as String? ??
        '';
    // Handle banner URL
    String? banner = inner['banner'] as String? ?? inner['details_banner'] as String? ?? inner['bannerUrl'] as String? ?? json['banner'] as String?;
    // Handle logo URL
    final logo = inner['logo'] as String? ?? json['logo'] as String?;

    // If no poster exists, fall back to banner or logo so the card never
    // renders an empty placeholder while the detail page has artwork.
    if (poster.isEmpty) {
      poster = (banner ?? logo) ?? '';
    }

    // Handle episode / season info
    String? epBadge;
    int? sNum;
    int? epNum;
    final epSource = inner['episode'] ?? json['episode'];
    if (epSource != null) {
      final epVal = epSource.toString();
      final seasonVal = (inner['season'] ?? json['season'])?.toString() ?? '1';
      epBadge = 'S$seasonVal:B$epVal';
      epNum = int.tryParse(epVal);
      sNum = int.tryParse(seasonVal);
    } else if (inner['currentEpisode'] != null || json['currentEpisode'] != null) {
      epBadge = (inner['currentEpisode'] ?? json['currentEpisode']).toString();
    }

    final id = (inner['ID'] ?? inner['id'] ?? inner['_id'] ?? json['ID'] ?? json['id'] ?? json['_id'] ?? '').toString();
    final title = inner['name'] as String? ?? inner['title'] as String? ?? json['name'] as String? ?? json['title'] as String? ?? '';

    return AnimeModel(
      id: id,
      title: title,
      posterUrl: ImageUtils.cleanImageUrl(poster),
      bannerUrl: banner != null ? ImageUtils.cleanImageUrl(banner) : null,
      logoUrl: logo != null && logo.isNotEmpty ? ImageUtils.cleanImageUrl(logo) : null,
      rating: parsedRating,
      currentEpisode: epBadge,
      genres: parsedGenres,
      status: (inner['status'] ?? json['status']) as String?,
      synopsis: (inner['overview'] ?? inner['synopsis'] ?? json['overview'] ?? json['synopsis']) as String?,
      seasonNumber: sNum,
      episodeNumber: epNum,
      watchProgress: ((inner['watchProgress'] ?? json['watchProgress']) as num?)?.toDouble(),
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
