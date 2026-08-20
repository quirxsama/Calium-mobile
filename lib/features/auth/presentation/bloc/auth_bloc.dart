import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/auth/domain/repositories/auth_repository.dart';
import 'package:calium_stream/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:calium_stream/features/auth/domain/usecases/login_usecase.dart';
import 'package:calium_stream/features/auth/domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._loginUseCase,
    required this._registerUseCase,
    required this._getCurrentUserUseCase,
    required this._authRepository,
  })  :
        super(AuthInitial()) {
    on<CheckAuthRequested>(_onCheckAuthRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UserSilentlyUpdated>((event, emit) {
      emit(Authenticated(user: event.user));
    });
  }


  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthRepository _authRepository;

  Future<void> _onCheckAuthRequested(
    CheckAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) {
      emit(AuthLoading());
    }
    final result = await _getCurrentUserUseCase();
    result.fold(
      (_) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _registerUseCase(
      RegisterParams(
        email: event.email,
        username: event.username,
        password: event.password,
      ),
    );
    result.fold(
      (failure) => emit(AuthFailureState(message: failure.message)),
      (user) => emit(Authenticated(user: user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
