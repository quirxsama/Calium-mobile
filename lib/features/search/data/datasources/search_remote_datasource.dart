import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/home/data/models/anime_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<AnimeModel>> searchAnime({
    required String query,
    int page = 1,
    String? genreId,
    String? type,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  const SearchRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  List<AnimeModel> _parseAnimeList(dynamic data) {
    if (data == null) return [];
    if (data is Map<String, dynamic>) {
      final pageData = data['page'];
      if (pageData is Map<String, dynamic> && pageData['data'] is List) {
        return (pageData['data'] as List)
            .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
    if (data is List) {
      return data
          .map((item) => AnimeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<AnimeModel>> searchAnime({
    required String query,
    int page = 1,
    String? genreId,
    String? type,
  }) async {
    try {
      if (query.trim().isNotEmpty) {
        try {
          final response = await _dioClient.get(
            '/api/anizium/search',
            queryParameters: {
              'q': query.trim(),
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } catch (_) {
          return [];
        }
      }

      if (genreId != null && genreId.isNotEmpty) {
        try {
          final response = await _dioClient.get(
            '/api/anizium/catalog',
            queryParameters: {
              'kind': 'genre',
              'id': genreId,
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } catch (_) {
          return [];
        }
      }

      if (type != null && type.isNotEmpty) {
        try {
          final response = await _dioClient.get(
            '/api/anizium/catalog',
            queryParameters: {
              'kind': type,
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } catch (_) {
          return [];
        }
      }

      // Default: top catalog
      try {
        final response = await _dioClient.get(
          '/api/anizium/top',
          queryParameters: {
            'page': page,
          },
        );
        return _parseAnimeList(response.data);
      } catch (_) {
        return [];
      }
    } catch (_) {
      return [];
    }
  }
}

