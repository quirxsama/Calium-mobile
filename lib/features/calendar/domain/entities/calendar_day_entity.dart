import 'package:equatable/equatable.dart';

class CalendarItemEntity extends Equatable {
  const CalendarItemEntity({
    required this.id,
    required this.animeId,
    required this.title,
    required this.posterUrl,
    this.seasonNumber,
    this.episodeNumber,
    this.releaseDate,
    this.category,
    this.isOnAir = false,
  });

  final String id;
  final String animeId;
  final String title;
  final String posterUrl;
  final int? seasonNumber;
  final int? episodeNumber;
  final DateTime? releaseDate;
  final String? category;
  final bool isOnAir;

  @override
  List<Object?> get props => [
        id,
        animeId,
        title,
        posterUrl,
        seasonNumber,
        episodeNumber,
        releaseDate,
        category,
        isOnAir,
      ];
}

class CalendarDayEntity extends Equatable {
  const CalendarDayEntity({
    required this.id,
    required this.title,
    this.dayName,
    this.monthName,
    required this.items,
  });

  final String id;
  final String title;
  final String? dayName;
  final String? monthName;
  final List<CalendarItemEntity> items;

  @override
  List<Object?> get props => [id, title, dayName, monthName, items];
}
