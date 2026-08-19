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
  const ProfileLoaded({required this.profile});
  final UserProfileEntity profile;

  ProfileLoaded copyWith({UserProfileEntity? profile}) {
    return ProfileLoaded(profile: profile ?? this.profile);
  }

  @override
  List<Object?> get props => [profile];
}

final class ProfileError extends ProfileState {
  const ProfileError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
