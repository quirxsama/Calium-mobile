import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
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
  const SearchRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

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
            '${ApiConstants.aniziumApiBaseUrl}/page/search',
            queryParameters: {
              'value': query.trim(),
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } on ServerException catch (e) {
          if (e.message.contains('502') ||
              e.message.contains('400') ||
              e.message.contains('500') ||
              e.message.contains('boş') ||
              e.message.contains('bulunamadı')) {
            return [];
          }
          return [];
        } catch (_) {
          return [];
        }
      }

      if (genreId != null && genreId.isNotEmpty) {
        try {
          final response = await _dioClient.get(
            '${ApiConstants.aniziumApiBaseUrl}/page/catalog',
            queryParameters: {
              'id': genreId,
              'type': 'genre',
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } on ServerException catch (e) {
          if (e.message.contains('502') ||
              e.message.contains('400') ||
              e.message.contains('500')) {
            return [];
          }
          return [];
        } catch (_) {
          return [];
        }
      }

      if (type != null && type.isNotEmpty) {
        try {
          final typeParam = type == 'trdub' ? 'sound_group' : 'type';
          final response = await _dioClient.get(
            '${ApiConstants.aniziumApiBaseUrl}/page/catalog',
            queryParameters: {
              'id': type,
              'type': typeParam,
              'page': page,
            },
          );
          return _parseAnimeList(response.data);
        } on ServerException catch (e) {
          if (e.message.contains('502') ||
              e.message.contains('400') ||
              e.message.contains('500')) {
            return [];
          }
          return [];
        } catch (_) {
          return [];
        }
      }

      // Default: top catalog
      try {
        final response = await _dioClient.get(
          '${ApiConstants.aniziumApiBaseUrl}/page/top',
          queryParameters: {
            'platform': 'favorite',
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

