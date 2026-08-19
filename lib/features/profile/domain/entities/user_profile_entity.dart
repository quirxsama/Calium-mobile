import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.isOwner = false,
    this.isPrivate = false,
    this.profilePublic = true,
    this.listsPublic = true,
    this.historyPublic = true,
    this.followStatus = 'not_following', // 'not_following' | 'following' | 'friends' | 'pending'
    this.favoritesCount = 0,
    this.listsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.recentHistory = const [],
    this.lists = const [],
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final bool isOwner;
  final bool isPrivate;
  final bool profilePublic;
  final bool listsPublic;
  final bool historyPublic;
  final String followStatus;
  final int favoritesCount;
  final int listsCount;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final List<ProfileHistoryItemEntity> recentHistory;
  final List<ProfileListItemEntity> lists;

  bool get isFollowing => followStatus == 'following' || followStatus == 'friends';

  UserProfileEntity copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    bool? isOwner,
    bool? isPrivate,
    bool? profilePublic,
    bool? listsPublic,
    bool? historyPublic,
    String? followStatus,
    int? favoritesCount,
    int? listsCount,
    int? followersCount,
    int? followingCount,
    int? friendsCount,
    List<ProfileHistoryItemEntity>? recentHistory,
    List<ProfileListItemEntity>? lists,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      isOwner: isOwner ?? this.isOwner,
      isPrivate: isPrivate ?? this.isPrivate,
      profilePublic: profilePublic ?? this.profilePublic,
      listsPublic: listsPublic ?? this.listsPublic,
      historyPublic: historyPublic ?? this.historyPublic,
      followStatus: followStatus ?? this.followStatus,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      listsCount: listsCount ?? this.listsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      friendsCount: friendsCount ?? this.friendsCount,
      recentHistory: recentHistory ?? this.recentHistory,
      lists: lists ?? this.lists,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        bio,
        createdAt,
        isOwner,
        isPrivate,
        profilePublic,
        listsPublic,
        historyPublic,
        followStatus,
        favoritesCount,
        listsCount,
        followersCount,
        followingCount,
        friendsCount,
        recentHistory,
        lists,
      ];
}

class ProfileHistoryItemEntity extends Equatable {
  const ProfileHistoryItemEntity({
    required this.animeId,
    required this.animeName,
    this.poster,
    required this.episodeId,
    required this.episodeName,
    this.episodeNumber,
    this.seasonNumber,
    this.progress = 0,
    this.duration = 0,
    this.updatedAt,
  });

  final String animeId;
  final String animeName;
  final String? poster;
  final String episodeId;
  final String episodeName;
  final int? episodeNumber;
  final int? seasonNumber;
  final double progress;
  final double duration;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        animeId,
        animeName,
        poster,
        episodeId,
        episodeName,
        episodeNumber,
        seasonNumber,
        progress,
        duration,
        updatedAt,
      ];
}

class ProfileListItemEntity extends Equatable {
  const ProfileListItemEntity({
    required this.id,
    required this.name,
    this.description,
    this.isPublic = true,
    this.itemCount = 0,
    this.likeCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final bool isPublic;
  final int itemCount;
  final int likeCount;

  @override
  List<Object?> get props => [id, name, description, isPublic, itemCount, likeCount];
}
