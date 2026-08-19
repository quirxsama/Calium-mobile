import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';

class GetHistoryUseCase {
  const GetHistoryUseCase({required LibraryRepository repository})
      : _repository = repository;

  final LibraryRepository _repository;

  Future<Either<Failure, List<HistoryEntity>>> call() {
    return _repository.getHistory();
  }
}
