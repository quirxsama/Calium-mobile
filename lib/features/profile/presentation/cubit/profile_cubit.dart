import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';
import 'package:calium_stream/features/profile/domain/repositories/profile_repository.dart';
import 'package:calium_stream/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this._repository})
      :
        super(ProfileInitial());

  final ProfileRepository _repository;

  Future<void> loadProfile({String? username}) async {
    emit(ProfileLoading());
    final res = (username != null && username.isNotEmpty)
        ? await _repository.getUserProfile(username)
        : await _repository.getCurrentUserProfile();

    await res.fold(
      (failure) async => emit(ProfileError(message: failure.message)),
      (profile) async => emit(await _loadComments(profile)),
    );
  }

  /// Loads the first page of comments for [profile] and returns a state that
  /// also carries the profile. Comment failures never hide the profile itself –
  /// they are surfaced as an inline error inside the comments tab.
  Future<ProfileLoaded> _loadComments(UserProfileEntity profile) async {
    if (profile.username.isEmpty) {
      return ProfileLoaded(profile: profile);
    }

    final commentsRes = await _repository.getUserComments(profile.username);
    return commentsRes.fold(
      (failure) => ProfileLoaded(
        profile: profile,
        commentsError: failure.message,
      ),
      (result) => ProfileLoaded(
        profile: profile.copyWith(
          comments: result.comments,
          commentsVisible: result.visible,
        ),
        nextCursor: result.nextCursor,
      ),
    );
  }

  Future<void> loadMoreComments() async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final cursor = current.nextCursor;
    if (cursor == null || cursor.isEmpty || current.isLoadingMoreComments) {
      return;
    }

    final username = current.profile.username;
    if (username.isEmpty) return;

    emit(
      current.copyWith(
        isLoadingMoreComments: true,
        clearCommentsError: true,
      ),
    );

    final res = await _repository.getUserComments(username, cursor: cursor);
    res.fold(
      (failure) => emit(
        current.copyWith(
          isLoadingMoreComments: false,
          commentsError: failure.message,
        ),
      ),
      (result) {
        final existingIds = current.profile.comments.map((c) => c.id).toSet();
        final merged = <ProfileCommentEntity>[
          ...current.profile.comments,
          ...result.comments.where((c) => !existingIds.contains(c.id)),
        ];
        emit(
          current.copyWith(
            profile: current.profile.copyWith(
              comments: merged,
              commentsVisible: result.visible,
            ),
            nextCursor: result.nextCursor,
            clearNextCursor: result.nextCursor == null,
            clearCommentsError: true,
            isLoadingMoreComments: false,
          ),
        );
      },
    );
  }

  Future<void> toggleFollow(String username) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final wasFollowing = current.profile.isFollowing;
    final newStatus = wasFollowing ? 'not_following' : 'following';
    final newFollowersCount = wasFollowing
        ? (current.profile.followersCount - 1).clamp(0, 999999)
        : current.profile.followersCount + 1;

    // Optimistic update
    emit(
      current.copyWith(
        profile: current.profile.copyWith(
          followStatus: newStatus,
          followersCount: newFollowersCount,
        ),
      ),
    );

    final res = await _repository.toggleFollow(username);
    res.fold(
      (_) {
        // Revert on error
        emit(current);
      },
      (status) {
        loadProfile(username: username);
      },
    );
  }
}
