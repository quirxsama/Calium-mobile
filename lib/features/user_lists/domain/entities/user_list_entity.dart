import 'package:equatable/equatable.dart';

class ListItemEntity extends Equatable {
  const ListItemEntity({
    required this.id,
    required this.listId,
    required this.animeId,
    required this.name,
    this.poster,
    required this.addedAt,
  });

  final String id;
  final String listId;
  final String animeId;
  final String name;
  final String? poster;
  final DateTime addedAt;

  @override
  List<Object?> get props => [id, listId, animeId, name, poster, addedAt];
}

class UserListEntity extends Equatable {
  const UserListEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.isPublic = true,
    this.itemCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.items = const [],
    this.creatorUsername,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isPublic;
  final int itemCount;
  final int likeCount;
  final bool isLiked;
  final List<ListItemEntity> items;
  final String? creatorUsername;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        isPublic,
        itemCount,
        likeCount,
        isLiked,
        items,
        creatorUsername,
        createdAt,
      ];
}
