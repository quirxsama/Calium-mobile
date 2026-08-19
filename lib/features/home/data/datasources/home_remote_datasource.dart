import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/home/data/models/anime_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<AnimeModel>> getLatestEpisodes({int page = 1});
  Future<List<AnimeModel>> getTopAnime({int page = 1});
  Future<List<AnimeModel>> getSeasonalAnime({int page = 1});
  Future<List<AnimeModel>> getTrDubAnime({int page = 1});
  Future<List<AnimeModel>> getActionAnime({int page = 1});
  Future<List<AnimeModel>> getIsekaiAnime({int page = 1});
  Future<List<AnimeModel>> getMovieAnime({int page = 1});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  List<AnimeModel> _parseAnimeList(dynamic data) {
    if (data == null) return [];
    if (data is Map<String, dynamic>) {
      final pageData = data['page'];
      if (pageData is Map<String, dynamic> && pageData['data'] is List) {
        return (pageData['data'] as List)
            .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
            .where((item) => item.id.isNotEmpty)
            .toList();
      }
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
            .where((item) => item.id.isNotEmpty)
            .toList();
      }
    }
    if (data is List) {
      return data
          .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
          .where((item) => item.id.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<List<AnimeModel>> _safeFetch(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dioClient.get(path, queryParameters: params);
      return _parseAnimeList(response.data);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AnimeModel>> getLatestEpisodes({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/last-added-episodes', params: {'page': page});
  }

  @override
  Future<List<AnimeModel>> getTopAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/top', params: {'platform': 'favorite', 'page': page});
  }

  @override
  Future<List<AnimeModel>> getSeasonalAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/catalog', params: {'id': 'series', 'type': 'type', 'page': page});
  }

  @override
  Future<List<AnimeModel>> getTrDubAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/catalog', params: {'id': 'trdub', 'type': 'sound_group', 'page': page});
  }

  @override
  Future<List<AnimeModel>> getActionAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/catalog', params: {'id': '62263', 'type': 'genre', 'page': page});
  }

  @override
  Future<List<AnimeModel>> getIsekaiAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/catalog', params: {'id': '23813', 'type': 'genre', 'page': page});
  }

  @override
  Future<List<AnimeModel>> getMovieAnime({int page = 1}) async {
    return _safeFetch('${ApiConstants.aniziumApiBaseUrl}/page/catalog', params: {'id': 'movie', 'type': 'type', 'page': page});
  }
}
