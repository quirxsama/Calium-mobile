import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    super.displayName,
    super.avatarUrl,
    super.bio,
    super.role = 'user',
    super.isPrivate = false,
    super.commentsPublic = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String? ?? 'user',
      isPrivate: json['isPrivate'] as bool? ?? false,
      commentsPublic: json['commentsPublic'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'role': role,
      'isPrivate': isPrivate,
      'commentsPublic': commentsPublic,
    };
  }
}
