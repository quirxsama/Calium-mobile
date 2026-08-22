import 'package:equatable/equatable.dart';

class FollowRequestEntity extends Equatable {
  const FollowRequestEntity({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl, createdAt];
}
