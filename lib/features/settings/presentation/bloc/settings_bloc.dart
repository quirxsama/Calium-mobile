import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/settings/data/repositories/settings_repository_impl.dart';

// ─── Events ──────────────────────────────────────────────────
sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class UpdateProfileRequested extends SettingsEvent {
  const UpdateProfileRequested({
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.isPrivate,
    this.dndEnabled,
  });

  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool? isPrivate;
  final bool? dndEnabled;

  @override
  List<Object?> get props => [displayName, bio, avatarUrl, isPrivate, dndEnabled];
}

final class ChangePasswordRequested extends SettingsEvent {
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

// ─── States ──────────────────────────────────────────────────
sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

final class SettingsInitial extends SettingsState {}

final class SettingsLoading extends SettingsState {}

final class SettingsSuccess extends SettingsState {
  const SettingsSuccess({this.updatedUser, required this.message});

  final UserEntity? updatedUser;
  final String message;

  @override
  List<Object?> get props => [updatedUser, message];
}

final class SettingsFailure extends SettingsState {
  const SettingsFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepository repository})
      : _repository = repository,
        super(SettingsInitial()) {
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<ChangePasswordRequested>(_onChangePassword);
  }

  final SettingsRepository _repository;

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final res = await _repository.updateProfile(
      displayName: event.displayName,
      bio: event.bio,
      avatarUrl: event.avatarUrl,
      isPrivate: event.isPrivate,
      dndEnabled: event.dndEnabled,
    );

    res.fold(
      (f) => emit(SettingsFailure(message: f.message)),
      (user) => emit(SettingsSuccess(updatedUser: user, message: 'Profil başarıyla güncellendi.')),
    );
  }

  Future<void> _onChangePassword(
    ChangePasswordRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final res = await _repository.changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
    );

    res.fold(
      (f) => emit(SettingsFailure(message: f.message)),
      (_) => emit(const SettingsSuccess(message: 'Şifreniz başarıyla değiştirildi.')),
    );
  }
}
