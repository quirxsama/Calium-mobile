import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/explore/data/datasources/explore_remote_datasource.dart';
import 'package:calium_stream/features/explore/domain/repositories/explore_repository.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  const ExploreRepositoryImpl({
    required ExploreRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ExploreRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<AnimeEntity>>> getCatalog({
    required String kind,
    String? genreId,
    int page = 1,
  }) async {
    try {
      final items = await _remoteDataSource.getCatalog(
        kind: kind,
        genreId: genreId,
        page: page,
      );
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
