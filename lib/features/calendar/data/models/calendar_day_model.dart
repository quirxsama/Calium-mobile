import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';

class CalendarItemModel extends CalendarItemEntity {
  const CalendarItemModel({
    required super.id,
    required super.animeId,
    required super.title,
    required super.posterUrl,
    super.seasonNumber,
    super.episodeNumber,
    super.releaseDate,
    super.category,
    super.isOnAir = false,
  });

  factory CalendarItemModel.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>? ?? json;

    DateTime? parsedDate;
    final rawDate = json['release_date'] ?? content['release_date'];
    if (rawDate != null) {
      if (rawDate is num) {
        final val = rawDate.toInt();
        parsedDate = DateTime.fromMillisecondsSinceEpoch(val < 10000000000 ? val * 1000 : val);
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      }
    }

    final rawPoster = content['poster'] as String? ??
        content['details_banner'] as String? ??
        content['banner'] as String? ??
        '';

    final rawCat = json['category'] is List 
        ? (json['category'] as List).join(', ')
        : json['category']?.toString();

    String? formattedCategory;
    if (rawCat != null && rawCat.isNotEmpty) {
      if (rawCat.contains('upcoming_4k')) {
        formattedCategory = 'Yaklaşan 4K';
      } else if (rawCat.contains('upcoming_trdub')) {
        formattedCategory = 'Yaklaşan Dublaj';
      } else if (rawCat.contains('upcoming_movie')) {
        formattedCategory = 'Yaklaşan Film';
      } else if (rawCat.contains('upcoming')) {
        formattedCategory = 'Yaklaşan İçerik';
      } else {
        formattedCategory = rawCat;
      }
    }

    return CalendarItemModel(
      id: (json['_id'] ?? json['ID'] ?? '').toString(),
      animeId: (json['content_id'] ?? json['ID'] ?? content['ID'] ?? '').toString(),
      title: content['name'] as String? ?? content['title'] as String? ?? 'Anime',
      posterUrl: ImageUtils.cleanImageUrl(rawPoster),
      seasonNumber: int.tryParse(json['season']?.toString() ?? ''),
      episodeNumber: int.tryParse(json['episode']?.toString() ?? ''),
      releaseDate: parsedDate,
      category: formattedCategory,
      isOnAir: json['on_air'] == true || json['active'] == true,
    );
  }
}

class CalendarDayModel extends CalendarDayEntity {
  const CalendarDayModel({
    required super.id,
    required super.title,
    super.dayName,
    super.monthName,
    required super.items,
  });

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    List<CalendarItemModel> items = [];
    if (json['contents'] is List) {
      for (final item in json['contents'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(CalendarItemModel.fromJson(item));
        }
      }
    }

    return CalendarDayModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? json['day_name'] as String? ?? 'Gün',
      dayName: json['day_name'] as String?,
      monthName: json['month_name'] as String?,
      items: items,
    );
  }
}
