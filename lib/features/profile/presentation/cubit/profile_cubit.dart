import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calium_stream/features/profile/domain/repositories/profile_repository.dart';
import 'package:calium_stream/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(ProfileInitial());

  final ProfileRepository _repository;

  Future<void> loadProfile({String? username}) async {
    emit(ProfileLoading());
    final res = (username != null && username.isNotEmpty)
        ? await _repository.getUserProfile(username)
        : await _repository.getCurrentUserProfile();

    res.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
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
      ProfileLoaded(
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
        emit(ProfileLoaded(profile: current.profile));
      },
      (status) {
        loadProfile(username: username);
      },
    );
  }
}
