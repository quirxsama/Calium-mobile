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
    this.commentsPublic = true,
    this.commentsVisible = true,
    this.followStatus = 'not_following', // 'not_following' | 'following' | 'friends' | 'pending'
    this.favoritesCount = 0,
    this.listsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.recentHistory = const [],
    this.lists = const [],
    this.comments = const [],
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
  final bool commentsPublic;
  final bool commentsVisible;
  final String followStatus;
  final int favoritesCount;
  final int listsCount;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final List<ProfileHistoryItemEntity> recentHistory;
  final List<ProfileListItemEntity> lists;
  final List<ProfileCommentEntity> comments;

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
    bool? commentsPublic,
    bool? commentsVisible,
    String? followStatus,
    int? favoritesCount,
    int? listsCount,
    int? followersCount,
    int? followingCount,
    int? friendsCount,
    List<ProfileHistoryItemEntity>? recentHistory,
    List<ProfileListItemEntity>? lists,
    List<ProfileCommentEntity>? comments,
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
      commentsPublic: commentsPublic ?? this.commentsPublic,
      commentsVisible: commentsVisible ?? this.commentsVisible,
      followStatus: followStatus ?? this.followStatus,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      listsCount: listsCount ?? this.listsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      friendsCount: friendsCount ?? this.friendsCount,
      recentHistory: recentHistory ?? this.recentHistory,
      lists: lists ?? this.lists,
      comments: comments ?? this.comments,
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
        commentsPublic,
        commentsVisible,
        followStatus,
        favoritesCount,
        listsCount,
        followersCount,
        followingCount,
        friendsCount,
        recentHistory,
        lists,
        comments,
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

/// A single comment authored by the profile owner.
///
/// [episodeId] is `null` for series-level comments; [canDelete] tells the UI
/// whether the currently authenticated user may remove it.
class ProfileCommentEntity extends Equatable {
  const ProfileCommentEntity({
    required this.id,
    required this.animeId,
    this.episodeId,
    this.body = '',
    this.createdAt,
    this.canDelete = false,
    this.authorDisplayName,
    this.authorUsername,
    this.authorAvatarUrl,
  });

  final String id;
  final String animeId;
  final String? episodeId;
  final String body;
  final DateTime? createdAt;
  final bool canDelete;
  final String? authorDisplayName;
  final String? authorUsername;
  final String? authorAvatarUrl;

  bool get isEpisodeComment => episodeId != null && episodeId!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        animeId,
        episodeId,
        body,
        createdAt,
        canDelete,
        authorDisplayName,
        authorUsername,
        authorAvatarUrl,
      ];
}

/// One page of [ProfileCommentEntity] results plus pagination/visibility info.
class ProfileCommentsResult extends Equatable {
  const ProfileCommentsResult({
    this.comments = const [],
    this.nextCursor,
    this.visible = true,
  });

  final List<ProfileCommentEntity> comments;
  final String? nextCursor;

  /// `false` when the user hid their comments (or the profile is restricted);
  /// the list is empty by design in that case.
  final bool visible;

  @override
  List<Object?> get props => [comments, nextCursor, visible];
}
