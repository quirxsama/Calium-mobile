import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';

class ListItemModel extends ListItemEntity {
  const ListItemModel({
    required super.id,
    required super.listId,
    required super.animeId,
    required super.name,
    super.poster,
    required super.addedAt,
  });

  factory ListItemModel.fromJson(Map<String, dynamic> json) {
    return ListItemModel(
      id: json['id']?.toString() ?? '',
      listId: json['listId']?.toString() ?? '',
      animeId: json['animeId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Anime',
      poster: ImageUtils.cleanImageUrl(json['poster']?.toString()),
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class UserListModel extends UserListEntity {
  const UserListModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    super.isPublic = true,
    super.itemCount = 0,
    super.likeCount = 0,
    super.isLiked = false,
    super.items = const [],
    super.creatorUsername,
    required super.createdAt,
  });

  factory UserListModel.fromJson(Map<String, dynamic> json) {
    List<ListItemModel> items = [];
    if (json['items'] is List) {
      for (final it in json['items'] as List) {
        if (it is Map<String, dynamic>) {
          items.add(ListItemModel.fromJson(it));
        }
      }
    }

    final userObj = json['user'] as Map<String, dynamic>?;

    return UserListModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Liste',
      description: json['description']?.toString(),
      isPublic: json['isPublic'] == true,
      itemCount: (json['_count']?['items'] as num?)?.toInt() ?? items.length,
      likeCount: (json['_count']?['likes'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      items: items,
      creatorUsername: userObj?['username']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
