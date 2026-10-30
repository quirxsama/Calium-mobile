import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.username,
    required super.displayName,
    super.avatarUrl,
    super.bio,
    super.createdAt,
    super.isOwner,
    super.isPrivate,
    super.profilePublic,
    super.listsPublic,
    super.historyPublic,
    super.commentsPublic,
    super.commentsVisible,
    super.followStatus,
    super.favoritesCount,
    super.listsCount,
    super.followersCount,
    super.followingCount,
    super.friendsCount,
    super.recentHistory,
    super.lists,
    super.comments,
  });

  /// Parses a single comment from `GET /api/users/{username}/comments`.
  ///
  /// Kept defensive: every field is optional in practice because the endpoint
  /// may evolve, and unknown/missing keys must never crash the profile screen.
  static ProfileCommentEntity commentFromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final episodeRaw = json['episodeId']?.toString();
    final createdAtRaw = json['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is num) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }
    final displayName = user['displayName']?.toString();
    final username = user['username']?.toString();
    return ProfileCommentEntity(
      id: json['id']?.toString() ?? '',
      animeId: json['animeId']?.toString() ?? '',
      episodeId: (episodeRaw == null || episodeRaw.isEmpty) ? null : episodeRaw,
      body: json['body']?.toString() ?? '',
      createdAt: createdAt,
      canDelete: json['canDelete'] as bool? ?? false,
      authorDisplayName: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : username,
      authorUsername: username,
      authorAvatarUrl: ImageUtils.cleanImageUrl(
        user['avatarUrl']?.toString() ?? user['avatar']?.toString(),
      ),
    );
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    final counts = user['_count'] as Map<String, dynamic>? ?? {};

    final isOwner = json['isOwner'] as bool? ?? false;
    final followStatus = json['followStatus'] as String? ?? 'not_following';

    final historyRaw = json['recentHistory'] as List? ?? [];
    final recentHistory = historyRaw.map((h) {
      final hm = h as Map<String, dynamic>;
      final updatedRaw = hm['updatedAt'];
      DateTime? updated;
      if (updatedRaw is num) {
        updated = DateTime.fromMillisecondsSinceEpoch(updatedRaw.toInt());
      } else if (updatedRaw is String) {
        updated = DateTime.tryParse(updatedRaw);
      }

      return ProfileHistoryItemEntity(
        animeId: hm['animeId']?.toString() ?? '',
        animeName: hm['animeName']?.toString() ?? 'Anime',
        poster: ImageUtils.cleanImageUrl(hm['poster']?.toString()),
        episodeId: hm['episodeId']?.toString() ?? '',
        episodeName: hm['episodeName']?.toString() ?? 'Bölüm',
        episodeNumber: (hm['episodeNumber'] as num?)?.toInt(),
        seasonNumber: (hm['seasonNumber'] as num?)?.toInt(),
        progress: (hm['progress'] as num?)?.toDouble() ?? 0,
        duration: (hm['duration'] as num?)?.toDouble() ?? 0,
        updatedAt: updated,
      );
    }).toList();

    final listsRaw = json['lists'] as List? ?? [];
    final lists = listsRaw.map((l) {
      final lm = l as Map<String, dynamic>;
      final listCounts = lm['_count'] as Map<String, dynamic>? ?? {};
      return ProfileListItemEntity(
        id: lm['id']?.toString() ?? '',
        name: lm['name']?.toString() ?? 'Liste',
        description: lm['description']?.toString(),
        isPublic: lm['isPublic'] as bool? ?? true,
        itemCount: (listCounts['items'] as num?)?.toInt() ?? 0,
        likeCount: (listCounts['likes'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    DateTime? createdAt;
    if (user['createdAt'] != null) {
      createdAt = DateTime.tryParse(user['createdAt'].toString());
    }

    final commentsRaw = json['comments'] as List? ?? [];
    final comments = commentsRaw
        .whereType<Map>()
        .map((c) => UserProfileModel.commentFromJson(
              Map<String, dynamic>.from(c),
            ))
        .toList();

    return UserProfileModel(
      id: user['id']?.toString() ?? '',
      username: user['username']?.toString() ?? '',
      displayName: user['displayName']?.toString() ?? user['username']?.toString() ?? 'Kullanıcı',
      avatarUrl: ImageUtils.cleanImageUrl(user['avatarUrl']?.toString() ?? user['avatar']?.toString()),
      bio: user['bio']?.toString(),
      createdAt: createdAt,
      isOwner: isOwner,
      isPrivate: user['isPrivate'] as bool? ?? false,
      profilePublic: user['profilePublic'] as bool? ?? true,
      listsPublic: user['listsPublic'] as bool? ?? true,
      historyPublic: user['historyPublic'] as bool? ?? true,
      commentsPublic: user['commentsPublic'] as bool? ?? true,
      commentsVisible: json['commentsVisible'] as bool? ?? true,
      followStatus: followStatus,
      favoritesCount: (counts['favorites'] as num?)?.toInt() ?? 0,
      listsCount: (counts['lists'] as num?)?.toInt() ?? 0,
      followersCount: (counts['followers'] as num?)?.toInt() ?? 0,
      followingCount: (counts['following'] as num?)?.toInt() ?? 0,
      friendsCount: (counts['friends'] as num?)?.toInt() ?? 0,
      recentHistory: recentHistory,
      lists: lists,
      comments: comments,
    );
  }
}
