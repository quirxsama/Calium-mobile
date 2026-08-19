import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/home_feed_entity.dart';
import 'package:calium_stream/features/home/domain/repositories/home_repository.dart';

class GetHomeFeedUseCase {
  const GetHomeFeedUseCase({required HomeRepository repository})
      : _repository = repository;

  final HomeRepository _repository;

  Future<Either<Failure, HomeFeedEntity>> call() {
    return _repository.getHomeFeed();
  }
}
