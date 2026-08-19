import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';
import 'package:calium_stream/features/calendar/domain/repositories/calendar_repository.dart';

class GetCalendarUseCase {
  const GetCalendarUseCase({required CalendarRepository repository})
      : _repository = repository;

  final CalendarRepository _repository;

  Future<Either<Failure, List<CalendarDayEntity>>> call() {
    return _repository.getCalendar();
  }
}
