import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';

class GetCastUseCase {
  const GetCastUseCase({required AnimeDetailRepository repository})
      : _repository = repository;

  final AnimeDetailRepository _repository;

  Future<Either<Failure, List<CastEntity>>> call(String tmdbId) {
    return _repository.getCast(tmdbId);
  }
}
