import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  const RoomEntity({
    required this.id,
    required this.code,
    required this.animeId,
    required this.animeName,
    this.episodeId,
    this.episodeName,
    this.poster,
    this.hostUsername,
    this.memberCount = 1,
    this.isPublic = true,
  });

  final String id;
  final String code;
  final String animeId;
  final String animeName;
  final String? episodeId;
  final String? episodeName;
  final String? poster;
  final String? hostUsername;
  final int memberCount;
  final bool isPublic;

  @override
  List<Object?> get props => [
        id,
        code,
        animeId,
        animeName,
        episodeId,
        episodeName,
        poster,
        hostUsername,
        memberCount,
        isPublic,
      ];
}

class SocialFriendEntity extends Equatable {
  const SocialFriendEntity({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.activityText,
    this.watchingAnimeId,
    this.watchingEpisodeId,
    this.roomId,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final String? activityText;
  final String? watchingAnimeId;
  final String? watchingEpisodeId;
  final String? roomId;

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        avatarUrl,
        isOnline,
        activityText,
        watchingAnimeId,
        watchingEpisodeId,
        roomId,
      ];
}
