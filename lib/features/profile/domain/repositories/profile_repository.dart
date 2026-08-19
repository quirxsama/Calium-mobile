import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String username);
  Future<Either<Failure, UserProfileEntity>> getCurrentUserProfile();
  Future<Either<Failure, String>> toggleFollow(String username);
}
