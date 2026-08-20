import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/exceptions.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';
import 'package:calium_stream/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl({required this._remoteDataSource});

  final CalendarRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<CalendarDayEntity>>> getCalendar() async {
    try {
      final days = await _remoteDataSource.getCalendar();
      return Right(days);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
