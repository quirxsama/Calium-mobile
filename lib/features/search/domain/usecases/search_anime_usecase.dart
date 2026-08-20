import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/search/domain/repositories/search_repository.dart';

class SearchAnimeParams extends Equatable {
  const SearchAnimeParams({
    required this.query,
    this.page = 1,
    this.genreId,
    this.type,
  });

  final String query;
  final int page;
  final String? genreId;
  final String? type;

  @override
  List<Object?> get props => [query, page, genreId, type];
}

class SearchAnimeUseCase {
  const SearchAnimeUseCase({required this._repository});

  final SearchRepository _repository;

  Future<Either<Failure, List<AnimeEntity>>> call(SearchAnimeParams params) {
    return _repository.searchAnime(
      query: params.query,
      page: params.page,
      genreId: params.genreId,
      type: params.type,
    );
  }
}
