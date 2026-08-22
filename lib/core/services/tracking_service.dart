import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  static const String _boxName = 'tracking_integrations';
  static const String _aniListTokenKey = 'anilist_token';
  static const String _aniListUserKey = 'anilist_user';
  static const String _malTokenKey = 'mal_token';
  static const String _malUserKey = 'mal_user';
  static const String _autoScrobbleKey = 'auto_scrobble';

  final Dio _dio = Dio();

  bool _initialized = false;
  String? _aniListToken;
  Map<String, dynamic>? _aniListUser;
  String? _malToken;
  Map<String, dynamic>? _malUser;
  bool _autoScrobble = true;

  bool get isAniListConnected => _aniListToken != null && _aniListToken!.isNotEmpty;
  bool get isMalConnected => _malToken != null && _malToken!.isNotEmpty;
  Map<String, dynamic>? get aniListUser => _aniListUser;
  Map<String, dynamic>? get malUser => _malUser;
  bool get autoScrobble => _autoScrobble;

  Future<void> init() async {
    if (_initialized) return;
    final box = await Hive.openBox(_boxName);
    _aniListToken = box.get(_aniListTokenKey) as String?;
    final rawAniUser = box.get(_aniListUserKey);
    if (rawAniUser is String) {
      try {
        _aniListUser = jsonDecode(rawAniUser) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawAniUser is Map) {
      _aniListUser = Map<String, dynamic>.from(rawAniUser);
    }

    _malToken = box.get(_malTokenKey) as String?;
    final rawMalUser = box.get(_malUserKey);
    if (rawMalUser is String) {
      try {
        _malUser = jsonDecode(rawMalUser) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawMalUser is Map) {
      _malUser = Map<String, dynamic>.from(rawMalUser);
    }

    _autoScrobble = (box.get(_autoScrobbleKey) as bool?) ?? true;
    _initialized = true;
  }

  Future<void> setAutoScrobble(bool enabled) async {
    _autoScrobble = enabled;
    final box = await Hive.openBox(_boxName);
    await box.put(_autoScrobbleKey, enabled);
  }

  // ─── AniList Integration ───────────────────────────────────────────

  Future<bool> connectAniList(String token) async {
    try {
      final cleanToken = token.trim();
      const query = '''
        query {
          Viewer {
            id
            name
            avatar {
              medium
              large
            }
          }
        }
      ''';

      final response = await _dio.post(
        'https://graphql.anilist.co',
        options: Options(
          headers: {
            'Authorization': 'Bearer $cleanToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final viewer = response.data['data']?['Viewer'];
        if (viewer != null) {
          _aniListToken = cleanToken;
          _aniListUser = Map<String, dynamic>.from(viewer as Map);

          final box = await Hive.openBox(_boxName);
          await box.put(_aniListTokenKey, cleanToken);
          await box.put(_aniListUserKey, jsonEncode(_aniListUser));
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ AniList connect error: $e');
      return false;
    }
  }

  Future<void> disconnectAniList() async {
    _aniListToken = null;
    _aniListUser = null;
    final box = await Hive.openBox(_boxName);
    await box.delete(_aniListTokenKey);
    await box.delete(_aniListUserKey);
  }

  Future<bool> scrobbleAniList({
    required String animeTitle,
    required int episode,
    bool isCompleted = false,
  }) async {
    if (!isAniListConnected || _aniListToken == null) return false;

    try {
      // Step 1: Find AniList Media ID
      const searchQuery = '''
        query (\$search: String) {
          Media(search: \$search, type: ANIME) {
            id
            title {
              romaji
              english
              native
            }
            episodes
          }
        }
      ''';

      final searchRes = await _dio.post(
        'https://graphql.anilist.co',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_aniListToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: jsonEncode({
          'query': searchQuery,
          'variables': {'search': animeTitle},
        }),
      );

      final mediaId = searchRes.data['data']?['Media']?['id'];
      final totalEpisodes = searchRes.data['data']?['Media']?['episodes'] as int?;
      if (mediaId == null) return false;

      final status = (isCompleted || (totalEpisodes != null && episode >= totalEpisodes))
          ? 'COMPLETED'
          : 'CURRENT';

      // Step 2: Save Media List Entry
      const mutateQuery = '''
        mutation (\$mediaId: Int, \$progress: Int, \$status: MediaListStatus) {
          SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress, status: \$status) {
            id
            progress
            status
          }
        }
      ''';

      final mutateRes = await _dio.post(
        'https://graphql.anilist.co',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_aniListToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: jsonEncode({
          'query': mutateQuery,
          'variables': {
            'mediaId': mediaId,
            'progress': episode,
            'status': status,
          },
        }),
      );

      return mutateRes.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ AniList scrobble error: $e');
      return false;
    }
  }

  // ─── MyAnimeList Integration ───────────────────────────────────────

  Future<bool> connectMal(String token) async {
    try {
      final cleanToken = token.trim();
      final response = await _dio.get(
        'https://api.myanimelist.net/v2/users/@me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $cleanToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _malToken = cleanToken;
        _malUser = Map<String, dynamic>.from(response.data as Map);

        final box = await Hive.openBox(_boxName);
        await box.put(_malTokenKey, cleanToken);
        await box.put(_malUserKey, jsonEncode(_malUser));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ MAL connect error: $e');
      return false;
    }
  }

  Future<void> disconnectMal() async {
    _malToken = null;
    _malUser = null;
    final box = await Hive.openBox(_boxName);
    await box.delete(_malTokenKey);
    await box.delete(_malUserKey);
  }

  Future<bool> scrobbleMal({
    required String animeTitle,
    required int episode,
    bool isCompleted = false,
  }) async {
    if (!isMalConnected || _malToken == null) return false;

    try {
      // Step 1: Search anime on MAL
      final searchRes = await _dio.get(
        'https://api.myanimelist.net/v2/anime',
        queryParameters: {'q': animeTitle, 'limit': 1},
        options: Options(
          headers: {'Authorization': 'Bearer $_malToken'},
        ),
      );

      final dataList = searchRes.data['data'] as List?;
      if (dataList == null || dataList.isEmpty) return false;
      final animeId = dataList.first['node']?['id'];
      if (animeId == null) return false;

      final status = isCompleted ? 'completed' : 'watching';

      // Step 2: Update status on MAL
      final updateRes = await _dio.put(
        'https://api.myanimelist.net/v2/anime/$animeId/my_list_status',
        data: {
          'status': status,
          'num_watched_episodes': episode,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_malToken',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      return updateRes.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ MAL scrobble error: $e');
      return false;
    }
  }

  // ─── Scrobble All Connected Providers ──────────────────────────────

  Future<void> scrobbleEpisode({
    required String animeTitle,
    required int episode,
    bool isCompleted = false,
  }) async {
    if (!_autoScrobble) return;

    if (isAniListConnected) {
      await scrobbleAniList(
        animeTitle: animeTitle,
        episode: episode,
        isCompleted: isCompleted,
      );
    }
    if (isMalConnected) {
      await scrobbleMal(
        animeTitle: animeTitle,
        episode: episode,
        isCompleted: isCompleted,
      );
    }
  }
}
