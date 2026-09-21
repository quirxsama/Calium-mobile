import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/home/data/models/anime_model.dart';

abstract class ExploreRemoteDataSource {
  Future<List<AnimeModel>> getCatalog({
    required String kind,
    String? genreId,
    int page = 1,
  });
}

class ExploreRemoteDataSourceImpl implements ExploreRemoteDataSource {
  const ExploreRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  List<AnimeModel> _parseList(dynamic data) {
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
  Future<List<AnimeModel>> getCatalog({
    required String kind,
    String? genreId,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> query = {
        'kind': kind,
        'page': page,
      };
      if (kind == 'genre' && genreId != null) {
        query['id'] = genreId;
      }

      final response = await _dioClient.get(
        '/api/anizium/catalog',
        queryParameters: query,
      );
      return _parseList(response.data);
    } catch (_) {
      return [];
    }
  }
}

