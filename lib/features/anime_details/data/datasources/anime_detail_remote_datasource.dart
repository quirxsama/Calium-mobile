import 'package:dio/dio.dart';
import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/home/data/models/anime_model.dart';
import 'package:calium_stream/features/anime_details/data/models/anime_detail_model.dart';
import 'package:calium_stream/features/anime_details/data/models/cast_model.dart';
import 'package:calium_stream/features/anime_details/data/models/episode_model.dart';

abstract class AnimeDetailRemoteDataSource {
  Future<AnimeDetailModel> getAnimeDetail(String animeId);
  Future<List<EpisodeModel>> getEpisodes({required String animeId, required int season});
  Future<List<CastModel>> getCast(String tmdbId);
  Future<List<AnimeModel>> getSimilarAnime(String animeId);
}

class AnimeDetailRemoteDataSourceImpl implements AnimeDetailRemoteDataSource {
  const AnimeDetailRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  @override
  Future<AnimeDetailModel> getAnimeDetail(String animeId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.aniziumApiBaseUrl}/anime/get',
        queryParameters: {'id': animeId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AnimeDetailModel.fromJson(data);
      }
      throw ServerException(message: 'Anime detayları alınamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<EpisodeModel>> getEpisodes({
    required String animeId,
    required int season,
  }) async {
    try {
      final detail = await getAnimeDetail(animeId);
      return detail.embeddedEpisodes[season] ?? [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CastModel>> getCast(String tmdbId) async {
    if (tmdbId.isEmpty || tmdbId == '0') return [];
    try {
      final response = await _dioClient.get(
        '/api/anizium/tmdb-credits',
        queryParameters: {'tmdbId': tmdbId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['cast'] is List) {
        return (data['cast'] as List)
            .map((c) => CastModel.fromJson(c as Map<String, dynamic>))
            .take(15)
            .toList();
      }
      // Direct TMDB fallback
      final apiKey = ApiConstants.tmdbApiKey;
      if (apiKey.isNotEmpty) {
        final fallback = await _dioClient.get(
          'https://api.themoviedb.org/3/tv/$tmdbId/credits',
          queryParameters: {'api_key': apiKey, 'language': 'tr-TR'},
        );
        final fbData = fallback.data;
        if (fbData is Map<String, dynamic> && fbData['cast'] is List) {
          return (fbData['cast'] as List)
              .map((c) => CastModel.fromJson(c as Map<String, dynamic>))
              .take(15)
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeModel>> getSimilarAnime(String animeId) async {
    final merged = <AnimeModel>[];
    final seenIds = <String>{animeId};

    void addAll(List<AnimeModel> items) {
      for (final item in items) {
        if (item.id.isEmpty || seenIds.contains(item.id)) continue;
        seenIds.add(item.id);
        merged.add(item);
      }
    }

    // 1. Try Calium backend similar route first (uses asset proxy, proper posters, and caching)
    try {
      final response = await _dioClient.get(
        '/api/anizium/anime/$animeId/similar',
      );
      final data = response.data;
      List<AnimeModel> list = [];
      if (data is Map<String, dynamic>) {
        final pageData = data['page'] ?? data;
        if (pageData is Map<String, dynamic> && pageData['data'] is List) {
          list = (pageData['data'] as List)
              .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
              .where((item) => item.id.isNotEmpty && item.id != animeId)
              .toList();
        } else if (data['data'] is List) {
          list = (data['data'] as List)
              .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
              .where((item) => item.id.isNotEmpty && item.id != animeId)
              .toList();
        }
      }
      addAll(list);
    } catch (_) {}

    // 2. Direct Anizium API fallback
    try {
      final directDio = Dio(
        BaseOptions(
          headers: {
            'User-Agent': ApiConstants.userAgent,
            'Referer': ApiConstants.referer,
            'Origin': ApiConstants.origin,
            'CF-Control': ApiConstants.cfControl,
            'User-Session': ApiConstants.userSession,
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final directResponse = await directDio.get(
        '${ApiConstants.aniziumApiBaseUrl}/anime/similar',
        queryParameters: {'id': animeId},
      );
      final directData = directResponse.data;
      if (directData is Map<String, dynamic>) {
        List items = [];
        if (directData['data'] is List) {
          items = directData['data'] as List;
        } else if (directData['page'] is Map && (directData['page'] as Map)['data'] is List) {
          items = (directData['page'] as Map)['data'] as List;
        }
        if (items.isNotEmpty) {
          addAll(items
              .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
              .where((item) => item.id.isNotEmpty && item.id != animeId)
              .toList());
        }
      }
    } catch (_) {}

    // 3. If fewer than 6 items, fill up with catalog recommendations
    if (merged.length < 6) {
      try {
        final fallback = await _dioClient.get(
          '/api/anizium/top',
          queryParameters: {'page': 1},
        );
        final fbData = fallback.data;
        if (fbData is Map<String, dynamic>) {
          final pageData = fbData['page'] ?? fbData;
          if (pageData is Map<String, dynamic> && pageData['data'] is List) {
            addAll((pageData['data'] as List)
                .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
                .where((item) => item.id.isNotEmpty && item.id != animeId)
                .toList());
          }
        }
      } catch (_) {}
    }

    // 4. Last resort: more catalog pages so we always have a healthy rail
    if (merged.length < 6) {
      try {
        final catalog = await _dioClient.get(
          '${ApiConstants.aniziumApiBaseUrl}/page/catalog',
          queryParameters: {'id': 'series', 'type': 'type', 'page': 1},
        );
        final catData = catalog.data;
        if (catData is Map<String, dynamic>) {
          final pageData = catData['page'] ?? catData;
          if (pageData is Map<String, dynamic> && pageData['data'] is List) {
            addAll((pageData['data'] as List)
                .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
                .where((item) => item.id.isNotEmpty && item.id != animeId)
                .toList());
          }
        }
      } catch (_) {}
    }

    return merged.take(12).toList();
  }
}


