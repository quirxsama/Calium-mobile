import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/data/models/episode_model.dart';

class AnimeDetailModel extends AnimeDetailEntity {
  const AnimeDetailModel({
    required super.id,
    required super.title,
    required super.posterUrl,
    super.originalTitle,
    super.bannerUrl,
    super.synopsis = '',
    super.rating,
    super.totalEpisodes,
    super.status,
    super.type,
    super.studio,
    super.year,
    super.genres = const [],
    super.seasons = const [],
    super.tmdbId,
    this.embeddedEpisodes = const {},
  });

  /// Map of season number to list of episodes parsed directly from detail response
  final Map<int, List<EpisodeModel>> embeddedEpisodes;

  factory AnimeDetailModel.fromJson(Map<String, dynamic> json) {
    // Check if response is wrapped in data
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final animeId = (data['ID'] ?? data['id'] ?? '').toString();

    // Rating
    double? rating;
    final rawRating = data['imdb_point'] ?? data['rating'] ?? data['score'];
    if (rawRating != null) {
      if (rawRating is num) rating = rawRating.toDouble();
      if (rawRating is String) rating = double.tryParse(rawRating);
    }

    // Year
    int? year;
    final rawYear = data['release_year'] ?? data['year'];
    if (rawYear != null) {
      if (rawYear is num) year = rawYear.toInt();
      if (rawYear is String) year = int.tryParse(rawYear);
    }

    // Studio
    String? studio;
    if (data['studios'] is List && (data['studios'] as List).isNotEmpty) {
      final firstStudio = (data['studios'] as List).first;
      if (firstStudio is Map) {
        studio = firstStudio['name'] as String?;
      }
    }

    // Genres
    List<String> genres = [];
    if (data['genre'] is List) {
      genres = (data['genre'] as List).map((g) {
        if (g is Map) return (g['name'] ?? '').toString();
        return g.toString();
      }).where((g) => g.isNotEmpty).toList();
    }

    // Seasons & Embedded Episodes
    List<SeasonEntity> seasons = [];
    Map<int, List<EpisodeModel>> embeddedEpisodes = {};

    if (data['seasons'] is List) {
      for (final s in data['seasons'] as List) {
        if (s is Map<String, dynamic>) {
          final sNum = int.tryParse(s['number']?.toString() ?? '1') ?? 1;
          final sName = s['name'] as String? ?? 'Sezon $sNum';

          List<EpisodeModel> episodes = [];
          if (s['episodes'] is List) {
            episodes = (s['episodes'] as List)
                .map((e) => EpisodeModel.fromJson(
                      e as Map<String, dynamic>,
                      animeId: animeId,
                      seasonNumber: sNum,
                    ))
                .toList();
          }

          seasons.add(
            SeasonEntity(
              seasonNumber: sNum,
              name: sName,
              episodeCount: episodes.length,
            ),
          );

          embeddedEpisodes[sNum] = episodes;
        }
      }
    }

    if (seasons.isEmpty) {
      seasons.add(const SeasonEntity(seasonNumber: 1, name: 'Sezon 1', episodeCount: 0));
    }

    // TMDB ID
    int? tmdbId;
    final rawTmdb = data['tmdb_id'];
    if (rawTmdb != null) {
      if (rawTmdb is num) tmdbId = rawTmdb.toInt();
      if (rawTmdb is String) tmdbId = int.tryParse(rawTmdb);
    }

    return AnimeDetailModel(
      id: animeId,
      title: data['name'] as String? ?? data['title'] as String? ?? '',
      originalTitle: data['name_jp'] as String? ?? data['originalTitle'] as String?,
      posterUrl: ImageUtils.cleanImageUrl(data['poster'] as String? ?? data['posterUrl'] as String?),
      bannerUrl: ImageUtils.cleanImageUrl(data['banner'] as String? ?? data['details_banner'] as String?),
      synopsis: data['overview'] as String? ?? data['synopsis'] as String? ?? '',
      rating: rating,
      totalEpisodes: data['total_episodes'] as int?,
      status: data['status'] as String?,
      type: data['type'] as String? ?? 'TV',
      studio: studio,
      year: year,
      genres: genres,
      seasons: seasons,
      tmdbId: tmdbId,
      embeddedEpisodes: embeddedEpisodes,
    );
  }
}
