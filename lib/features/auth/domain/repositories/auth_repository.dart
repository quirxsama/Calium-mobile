import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String username,
    required String password,
  });

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> logout();
}
