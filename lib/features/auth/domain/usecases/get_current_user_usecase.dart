import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/auth/domain/entities/user_entity.dart';
import 'package:calium_stream/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase({required this._repository});

  final AuthRepository _repository;

  Future<Either<Failure, UserEntity>> call() {
    return _repository.getCurrentUser();
  }
}
