import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/library/data/datasources/library_local_datasource.dart';
import 'package:calium_stream/features/library/data/datasources/library_remote_datasource.dart';
import 'package:calium_stream/features/library/data/models/favorite_model.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl({
    required this._localDataSource,
    required this._remoteDataSource,
  });

  final LibraryLocalDataSource _localDataSource;
  final LibraryRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<FavoriteEntity>>> getFavorites() async {
    try {
      // 1. Read local Hive
      final localList = await _localDataSource.getFavorites();

      // 2. Try fetching from Cloud
      final cloudList = await _remoteDataSource.fetchFavoritesFromCloud();
      if (cloudList.isNotEmpty) {
        await _localDataSource.saveFavoritesBulk(cloudList);
        final merged = await _localDataSource.getFavorites();
        return Right(merged);
      }

      // If local has items and cloud was empty, push local to cloud
      if (localList.isNotEmpty) {
        _remoteDataSource.syncFavorites(localList);
      }

      return Right(localList);
    } catch (e) {
      final list = await _localDataSource.getFavorites();
      return Right(list);
    }
  }

  @override
  Future<Either<Failure, bool>> toggleFavorite(FavoriteEntity favorite) async {
    try {
      final model = FavoriteModel(
        animeId: favorite.animeId,
        name: favorite.name,
        posterUrl: favorite.posterUrl,
        addedAt: favorite.addedAt,
      );
      final isNowFavorite = await _localDataSource.toggleFavorite(model);

      // Cloud sync - await to ensure cloud is updated before next fetch
      final currentList = await _localDataSource.getFavorites();
      await _remoteDataSource.syncFavorites(currentList);

      return Right(isNowFavorite);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HistoryEntity>>> getHistory() async {
    try {
      // 1. Read local Hive
      final localList = await _localDataSource.getHistory();

      // 2. Try fetching from Cloud
      final cloudList = await _remoteDataSource.fetchHistoryFromCloud();
      if (cloudList.isNotEmpty) {
        await _localDataSource.saveHistoryBulk(cloudList);
        final merged = await _localDataSource.getHistory();
        return Right(merged);
      }

      // If local has items and cloud was empty, push local to cloud
      if (localList.isNotEmpty) {
        _remoteDataSource.syncHistory(localList);
      }

      return Right(localList);
    } catch (e) {
      final list = await _localDataSource.getHistory();
      return Right(list);
    }
  }

  @override
  Future<Either<Failure, void>> removeHistoryItem(String animeId) async {
    try {
      await _localDataSource.deleteHistoryItem(animeId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await _localDataSource.clearHistory();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithCloud() async {
    try {
      final favorites = await _localDataSource.getFavorites();
      final history = await _localDataSource.getHistory();

      await _remoteDataSource.syncFavorites(favorites);
      await _remoteDataSource.syncHistory(history);

      return const Right(null);
    } catch (_) {
      return const Right(null);
    }
  }
}
