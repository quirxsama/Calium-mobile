import 'package:equatable/equatable.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    required this.profile,
    this.nextCursor,
    this.isLoadingMoreComments = false,
    this.commentsError,
  });

  final UserProfileEntity profile;
  final String? nextCursor;
  final bool isLoadingMoreComments;
  final String? commentsError;

  bool get hasMoreComments => nextCursor != null && nextCursor!.isNotEmpty;

  ProfileLoaded copyWith({
    UserProfileEntity? profile,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMoreComments,
    String? commentsError,
    bool clearCommentsError = false,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMoreComments: isLoadingMoreComments ?? this.isLoadingMoreComments,
      commentsError:
          clearCommentsError ? null : (commentsError ?? this.commentsError),
    );
  }

  @override
  List<Object?> get props => [
        profile,
        nextCursor,
        isLoadingMoreComments,
        commentsError,
      ];
}

final class ProfileError extends ProfileState {
  const ProfileError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
