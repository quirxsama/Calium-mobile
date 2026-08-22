import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/player/data/models/intro_song_model.dart';
import 'package:calium_stream/features/player/data/models/video_source_model.dart';

abstract class PlayerRemoteDataSource {
  Future<VideoSourceModel> getVideoSources({
    required String animeId,
    required int season,
    required int episode,
  });

  Future<IntroSongModel?> getIntroSong({
    required String animeId,
    required String episodeId,
    String? animeName,
    int? season,
    int? episode,
    int? introStart,
    String? streamUrl,
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

  @override
  Future<IntroSongModel?> getIntroSong({
    required String animeId,
    required String episodeId,
    String? animeName,
    int? season,
    int? episode,
    int? introStart,
    String? streamUrl,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'animeId': animeId,
        'episodeId': episodeId,
      };
      if (animeName != null && animeName.isNotEmpty) {
        queryParams['animeName'] = animeName;
      }
      if (season != null) {
        queryParams['season'] = season;
      }
      if (episode != null) {
        queryParams['episode'] = episode;
      }
      if (introStart != null) {
        queryParams['introStart'] = introStart;
      }
      if (streamUrl != null && streamUrl.isNotEmpty) {
        queryParams['streamUrl'] = streamUrl;
      }

      final response = await _dioClient.get(
        '/api/anime/intro-song',
        queryParameters: queryParams,
      );

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['found'] == true && data['song'] is Map<String, dynamic>) {
          return IntroSongModel.fromJson(data['song'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
