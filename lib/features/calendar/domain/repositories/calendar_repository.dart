import 'package:dartz/dartz.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';

abstract class CalendarRepository {
  Future<Either<Failure, List<CalendarDayEntity>>> getCalendar();
}
