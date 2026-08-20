import 'package:dio/dio.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/network/dio_client.dart';
import 'package:calium_stream/features/user_lists/data/models/user_list_model.dart';

abstract class UserListsRemoteDataSource {
  Future<List<UserListModel>> getMyLists();
  Future<List<UserListModel>> getPublicLists();
  Future<UserListModel> getListDetails(String listId);
  Future<UserListModel> createList({
    required String name,
    String? description,
    bool isPublic = true,
  });
  Future<void> addAnimeToList({
    required String listId,
    required String animeId,
    required String animeName,
    String? poster,
  });
  Future<void> removeAnimeFromList({
    required String listId,
    required String animeId,
  });
  Future<bool> toggleLikeList(String listId, {bool? currentlyLiked});
  Future<void> deleteList(String listId);
}

class UserListsRemoteDataSourceImpl implements UserListsRemoteDataSource {
  const UserListsRemoteDataSourceImpl({required this._dioClient});

  final DioClient _dioClient;

  @override
  Future<List<UserListModel>> getMyLists() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>('/api/lists?mode=my');
      final data = response.data;
      if (data != null && data['lists'] is List) {
        return (data['lists'] as List)
            .map((l) => UserListModel.fromJson(l as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<UserListModel>> getPublicLists() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>('/api/lists');
      final data = response.data;
      if (data != null && data['lists'] is List) {
        return (data['lists'] as List)
            .map((l) => UserListModel.fromJson(l as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserListModel> getListDetails(String listId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>('/api/lists/$listId');
      final data = response.data;
      if (data != null && data['list'] != null) {
        return UserListModel.fromJson(data['list'] as Map<String, dynamic>);
      }
      throw ServerException(message: 'Liste bulunamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserListModel> createList({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final response = await _dioClient.post<Map<String, dynamic>>(
        '/api/lists',
        data: {
          'name': name,
          'description': description,
          'isPublic': isPublic,
        },
      );
      final data = response.data;
      if (data != null && data['list'] != null) {
        return UserListModel.fromJson(data['list'] as Map<String, dynamic>);
      }
      throw ServerException(message: data?['error']?.toString() ?? 'Liste oluşturulamadı.');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> addAnimeToList({
    required String listId,
    required String animeId,
    required String animeName,
    String? poster,
  }) async {
    try {
      await _dioClient.post<void>(
        '/api/lists/$listId/items',
        data: {
          'animeId': animeId,
          'name': animeName,
          'poster': poster,
        },
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> removeAnimeFromList({
    required String listId,
    required String animeId,
  }) async {
    try {
      await _dioClient.delete<void>(
        '/api/lists/$listId/items',
        data: {'animeId': animeId},
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> toggleLikeList(String listId, {bool? currentlyLiked}) async {
    try {
      final Response<Map<String, dynamic>> response;
      if (currentlyLiked == true) {
        response = await _dioClient.delete<Map<String, dynamic>>('/api/lists/$listId/like');
      } else {
        response = await _dioClient.post<Map<String, dynamic>>('/api/lists/$listId/like');
      }
      final data = response.data;
      if (data != null && data['liked'] != null) {
        return data['liked'] == true;
      }
      return currentlyLiked != true;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteList(String listId) async {
    try {
      await _dioClient.delete<void>('/api/lists/$listId');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
