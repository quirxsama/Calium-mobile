import 'package:calium_stream/core/constants/api_constants.dart';

/// Defines cache duration policies for each endpoint category.
///
/// Each policy wraps the corresponding TTL from [ApiConstants] as a [Duration],
/// making it convenient to pass directly to cache interceptors and repositories.
enum CachePolicy {
  /// Latest/new releases – 10 minutes.
  latest(Duration(seconds: ApiConstants.cacheTtlLatest)),

  /// Airing calendar – 15 minutes.
  calendar(Duration(seconds: ApiConstants.cacheTtlCalendar)),

  /// Catalog / browse pages – 30 minutes.
  catalog(Duration(seconds: ApiConstants.cacheTtlCatalog)),

  /// Top / ranking lists – 30 minutes.
  top(Duration(seconds: ApiConstants.cacheTtlTop)),

  /// Anime detail pages – 1 hour.
  detail(Duration(seconds: ApiConstants.cacheTtlDetail)),

  /// Search results – 5 minutes.
  search(Duration(seconds: ApiConstants.cacheTtlSearch)),

  /// TMDB cast information – 2 hours.
  tmdbCast(Duration(seconds: ApiConstants.cacheTtlTmdbCast));

  const CachePolicy(this.duration);

  /// The cache duration for this policy.
  final Duration duration;

  /// Returns the duration in seconds (useful for raw cache headers).
  int get inSeconds => duration.inSeconds;
}
