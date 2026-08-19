import 'package:calium_stream/core/utils/image_utils.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';

class FavoriteModel extends FavoriteEntity {
  const FavoriteModel({
    required super.animeId,
    required super.name,
    required super.posterUrl,
    required super.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['addedAt'];
    if (rawDate != null) {
      if (rawDate is num) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate.toInt());
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
    }

    final rawPoster = json['poster'] as String? ?? json['posterUrl'] as String? ?? '';

    return FavoriteModel(
      animeId: (json['animeId'] ?? json['id'] ?? '').toString(),
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      posterUrl: ImageUtils.cleanImageUrl(rawPoster),
      addedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': animeId,
      'name': name,
      'poster': posterUrl,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }
}
