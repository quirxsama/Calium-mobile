import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/player/data/models/video_source_model.dart';

abstract class PlayerRemoteDataSource {
  Future<VideoSourceModel> getVideoSources({
    required String animeId,
    required int season,
    required int episode,
  });
}

class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  const PlayerRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  @override
  Future<VideoSourceModel> getVideoSources({
    required String animeId,
    required int season,
    required int episode,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.aniziumApiBaseUrl}/anime/source',
        queryParameters: {
          'id': animeId,
          'season': season,
          'episode': episode,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return VideoSourceModel.fromJson(data);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
