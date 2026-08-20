import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';

class SearchedUserEntity {
  const SearchedUserEntity({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isPrivate = false,
    this.followStatus = 'none', // 'none' | 'following' | 'friends' | 'pending'
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isPrivate;
  final String followStatus;
}

abstract class SocialRemoteDataSource {
  Future<List<RoomEntity>> getPublicRooms();
  Future<List<RoomEntity>> getMyRooms();
  Future<RoomEntity> joinRoomByCode(String code);
  Future<RoomEntity> createRoom({
    required String animeId,
    required String animeName,
    required String episodeId,
    String? episodeName,
    String? poster,
    bool isPublic = true,
  });
  Future<void> closeRoom(String roomId);
  Future<void> leaveRoom(String roomId);
  Future<List<SocialFriendEntity>> getFriends();
  Future<List<SearchedUserEntity>> searchUsers(String query);
  Future<String> toggleFollow(String username);
}

class SocialRemoteDataSourceImpl implements SocialRemoteDataSource {
  const SocialRemoteDataSourceImpl({
    required this._dioClient,
    required this._secureStorage,
  });

  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<List<RoomEntity>> getPublicRooms() async {
    try {
      final response = await _dioClient.patch<Map<String, dynamic>>(
        '/api/rooms?mode=public',
      );
      final data = response.data;
      if (data != null && data['rooms'] is List) {
        return (data['rooms'] as List).map((r) {
          final host = r['host'] as Map<String, dynamic>?;
          return RoomEntity(
            id: r['id']?.toString() ?? '',
            code: r['code']?.toString() ?? '',
            animeId: r['animeId']?.toString() ?? '',
            animeName: r['animeName']?.toString() ?? '',
            episodeId: r['episodeId']?.toString(),
            episodeName: r['episodeName']?.toString(),
            poster: ImageUtils.cleanImageUrl(r['poster']?.toString()),
            hostUsername: host?['username']?.toString() ?? 'Host',
            memberCount: (r['_count']?['members'] as num?)?.toInt() ?? 1,
            isPublic: true,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<RoomEntity>> getMyRooms() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>('/api/rooms');
      final data = response.data;
      if (data != null && data['rooms'] is List) {
        return (data['rooms'] as List).map((r) {
          return RoomEntity(
            id: r['id']?.toString() ?? '',
            code: r['code']?.toString() ?? '',
            animeId: r['animeId']?.toString() ?? '',
            animeName: r['animeName']?.toString() ?? '',
            episodeId: r['episodeId']?.toString(),
            episodeName: r['episodeName']?.toString(),
            poster: ImageUtils.cleanImageUrl(r['poster']?.toString()),
            memberCount: (r['_count']?['members'] as num?)?.toInt() ?? 1,
            isPublic: r['isPublic'] as bool? ?? true,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<RoomEntity> joinRoomByCode(String code) async {
    try {
      final response = await _dioClient.post(
        '/api/rooms/invite',
        data: {'code': code.trim().toUpperCase()},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true && data['room'] != null) {
        final r = data['room'] as Map<String, dynamic>;
        return RoomEntity(
          id: r['id']?.toString() ?? '',
          code: r['code']?.toString() ?? code,
          animeId: r['animeId']?.toString() ?? '',
          animeName: r['animeName']?.toString() ?? 'Anime',
          episodeId: r['episodeId']?.toString(),
          episodeName: r['episodeName']?.toString(),
          poster: ImageUtils.cleanImageUrl(r['poster']?.toString()),
        );
      }
      throw ServerException(message: data['error']?.toString() ?? 'Odaya katılamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<RoomEntity> createRoom({
    required String animeId,
    required String animeName,
    required String episodeId,
    String? episodeName,
    String? poster,
    bool isPublic = true,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/rooms',
        data: {
          'animeId': animeId,
          'animeName': animeName,
          'episodeId': episodeId,
          'episodeName': episodeName,
          'poster': poster,
          'isPublic': isPublic,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['success'] == true && data['room'] != null) {
        final r = data['room'] as Map<String, dynamic>;
        return RoomEntity(
          id: r['id']?.toString() ?? '',
          code: r['code']?.toString() ?? '',
          animeId: animeId,
          animeName: animeName,
          episodeId: episodeId,
          episodeName: episodeName,
          poster: ImageUtils.cleanImageUrl(poster),
          isPublic: isPublic,
        );
      }
      throw ServerException(message: data['error']?.toString() ?? 'Oda oluşturulamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> closeRoom(String roomId) async {
    try {
      await _dioClient.delete('/api/rooms/$roomId');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Oda kapatılamadı: $e');
    }
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    try {
      await _dioClient.post('/api/rooms/$roomId/leave');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Odadan ayrılınamadı: $e');
    }
  }

  @override
  Future<List<SocialFriendEntity>> getFriends() async {
    final Map<String, SocialFriendEntity> friendsMap = {};

    final currentUsername = await _secureStorage.read(key: StorageKeys.currentUser);
    final userPath = (currentUsername != null && currentUsername.isNotEmpty)
        ? currentUsername
        : 'me';

    // 1. Fetch mutual friends
    try {
      final response = await _dioClient.get(
        '/api/users/$userPath/friends',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        for (final u in data['items'] as List) {
          final act = u['activity'] as Map<String, dynamic>?;
          final entity = SocialFriendEntity(
            id: u['id']?.toString() ?? '',
            username: u['username']?.toString() ?? '',
            displayName: u['displayName']?.toString(),
            avatarUrl: ImageUtils.cleanImageUrl(u['avatarUrl']?.toString()),
            isOnline: u['isOnline'] == true,
            activityText: act != null ? act['animeTitle']?.toString() : null,
            watchingAnimeId: act?['animeId']?.toString(),
            watchingEpisodeId: act?['episodeId']?.toString(),
            roomId: act?['roomId']?.toString(),
          );
          friendsMap[entity.id] = entity;
        }
      }
    } catch (_) {}

    // 2. Fetch following
    try {
      final response = await _dioClient.get(
        '/api/users/$userPath/following',
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        for (final u in data['items'] as List) {
          final id = u['id']?.toString() ?? '';
          if (!friendsMap.containsKey(id)) {
            friendsMap[id] = SocialFriendEntity(
              id: id,
              username: u['username']?.toString() ?? '',
              displayName: u['displayName']?.toString(),
              avatarUrl: ImageUtils.cleanImageUrl(u['avatarUrl']?.toString()),
              isOnline: u['isOnline'] == true,
            );
          }
        }
      }
    } catch (_) {}

    return friendsMap.values.toList();
  }

  @override
  Future<List<SearchedUserEntity>> searchUsers(String query) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '/api/users/search',
        queryParameters: {'q': query},
      );
      final data = response.data;
      if (data != null && data['items'] is List) {
        return (data['items'] as List).map((u) {
          return SearchedUserEntity(
            id: u['id']?.toString() ?? '',
            username: u['username']?.toString() ?? '',
            displayName: u['displayName']?.toString(),
            avatarUrl: ImageUtils.cleanImageUrl(u['avatarUrl']?.toString()),
            isPrivate: u['isPrivate'] == true,
            followStatus: u['followStatus']?.toString() ?? 'none',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> toggleFollow(String username) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>('/api/users/$username/follow');
      final data = response.data;
      if (data != null) {
        return data['status']?.toString() ?? 'followed';
      }
      return 'followed';
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
