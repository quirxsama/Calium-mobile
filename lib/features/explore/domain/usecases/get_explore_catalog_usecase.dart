import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/explore/domain/repositories/explore_repository.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class GetExploreCatalogParams extends Equatable {
  const GetExploreCatalogParams({
    required this.kind,
    this.genreId,
    this.page = 1,
  });

  final String kind;
  final String? genreId;
  final int page;

  @override
  List<Object?> get props => [kind, genreId, page];
}

class GetExploreCatalogUseCase {
  const GetExploreCatalogUseCase({required this._repository});

  final ExploreRepository _repository;

  Future<Either<Failure, List<AnimeEntity>>> call(
    GetExploreCatalogParams params,
  ) {
    return _repository.getCatalog(
      kind: params.kind,
      genreId: params.genreId,
      page: params.page,
    );
  }
}
