import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';

class GetAnimeDetailUseCase {
  const GetAnimeDetailUseCase({required AnimeDetailRepository repository})
      : _repository = repository;

  final AnimeDetailRepository _repository;

  Future<Either<Failure, AnimeDetailEntity>> call(String animeId) {
    return _repository.getAnimeDetail(animeId);
  }
}
