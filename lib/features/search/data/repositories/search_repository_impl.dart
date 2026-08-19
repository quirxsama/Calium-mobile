import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/search/data/datasources/search_remote_datasource.dart';
import 'package:calium_stream/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl({
    required SearchRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SearchRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<AnimeEntity>>> searchAnime({
    required String query,
    int page = 1,
    String? genreId,
    String? type,
  }) async {
    try {
      final results = await _remoteDataSource.searchAnime(
        query: query,
        page: page,
        genreId: genreId,
        type: type,
      );
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
