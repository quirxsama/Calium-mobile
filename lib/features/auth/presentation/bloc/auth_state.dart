part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class Authenticated extends AuthState {
  const Authenticated({required this.user});

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {}

final class AuthFailureState extends AuthState {
  const AuthFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
