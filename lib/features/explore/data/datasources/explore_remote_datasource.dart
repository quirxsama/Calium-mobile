import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
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
      final Map<String, dynamic> query = {'page': page};

      switch (kind) {
        case 'series':
          query['id'] = 'series';
          query['type'] = 'type';
          break;
        case 'movie':
          query['id'] = 'movie';
          query['type'] = 'type';
          break;
        case 'trdub':
          query['id'] = 'trdub';
          query['type'] = 'sound_group';
          break;
        case 'genre':
          query['id'] = genreId ?? '62263';
          query['type'] = 'genre';
          break;
        default:
          query['id'] = kind;
          query['type'] = 'type';
      }

      final response = await _dioClient.get(
        '${ApiConstants.aniziumApiBaseUrl}/page/catalog',
        queryParameters: query,
      );
      return _parseList(response.data);
    } on ServerException catch (e) {
      if (e.message.contains('502') ||
          e.message.contains('400') ||
          e.message.contains('500') ||
          e.message.contains('bulunamadı')) {
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

