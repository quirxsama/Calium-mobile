import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.role = 'user',
    this.isPrivate = false,
    this.commentsPublic = true,
  });

  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String role;
  final bool isPrivate;
  final bool commentsPublic;

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        displayName,
        avatarUrl,
        bio,
        role,
        isPrivate,
        commentsPublic,
      ];
}
