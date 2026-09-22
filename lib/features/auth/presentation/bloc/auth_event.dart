part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class CheckAuthRequested extends AuthEvent {}

final class LoginRequested extends AuthEvent {
  const LoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.email,
    required this.username,
    required this.password,
  });

  final String email;
  final String username;
  final String password;

  @override
  List<Object?> get props => [email, username, password];
}

final class LogoutRequested extends AuthEvent {}

final class UserSilentlyUpdated extends AuthEvent {
  const UserSilentlyUpdated(this.user);
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class OAuthLoginRequested extends AuthEvent {
  const OAuthLoginRequested({
    required this.provider,
    required this.onOpenUrl,
  });

  final String provider;
  final Future<void> Function(String url) onOpenUrl;

  @override
  List<Object?> get props => [provider];
}

