import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';
import 'package:calium_stream/features/calendar/domain/usecases/get_calendar_usecase.dart';

// ─── Events ──────────────────────────────────────────────────
sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

final class LoadCalendarRequested extends CalendarEvent {}

// ─── States ──────────────────────────────────────────────────
sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

final class CalendarInitial extends CalendarState {}

final class CalendarLoading extends CalendarState {}

final class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.days,
    this.selectedDayIndex = 0,
  });

  final List<CalendarDayEntity> days;
  final int selectedDayIndex;

  CalendarLoaded copyWith({
    List<CalendarDayEntity>? days,
    int? selectedDayIndex,
  }) {
    return CalendarLoaded(
      days: days ?? this.days,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
    );
  }

  @override
  List<Object?> get props => [days, selectedDayIndex];
}

final class CalendarFailure extends CalendarState {
  const CalendarFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({required this._getCalendarUseCase})
      :
        super(CalendarInitial()) {
    on<LoadCalendarRequested>(_onLoadCalendar);
  }

  final GetCalendarUseCase _getCalendarUseCase;

  Future<void> _onLoadCalendar(
    LoadCalendarRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());

    final result = await _getCalendarUseCase();
    result.fold(
      (failure) => emit(CalendarFailure(message: failure.message)),
      (days) => emit(CalendarLoaded(days: days)),
    );
  }
}
