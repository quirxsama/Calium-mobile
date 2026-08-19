import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/auth/domain/repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  const RegisterParams({
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

class RegisterUseCase {
  const RegisterUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      username: params.username,
      password: params.password,
    );
  }
}
