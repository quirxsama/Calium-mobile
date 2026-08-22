import 'package:equatable/equatable.dart';

class AppNotificationEntity extends Equatable {
  const AppNotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.avatarUrl,
    this.actorUsername,
    this.animeId,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type; // 'follow', 'follow_request', 'follow_accepted', 'new_episode', 'room_invite'
  final String title;
  final String body;
  final String? avatarUrl;
  final String? actorUsername;
  final String? animeId;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        avatarUrl,
        actorUsername,
        animeId,
        readAt,
        createdAt,
      ];
}
