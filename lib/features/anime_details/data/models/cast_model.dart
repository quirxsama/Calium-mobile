import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';

class CastModel extends CastEntity {
  const CastModel({
    required super.id,
    required super.characterName,
    super.characterImageUrl,
    super.voiceActorName,
    super.voiceActorImageUrl,
    super.language = 'Japanese',
  });

  factory CastModel.fromJson(Map<String, dynamic> json) {
    String? profilePath = json['profile_path'] as String?;
    if (profilePath != null && !profilePath.startsWith('http')) {
      profilePath = 'https://image.tmdb.org/t/p/w185$profilePath';
    }

    return CastModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      characterName: json['character'] as String? ?? json['character_name'] as String? ?? '',
      characterImageUrl: json['character_image'] as String?,
      voiceActorName: json['name'] as String? ?? json['actor_name'] as String?,
      voiceActorImageUrl: profilePath ?? json['actor_image'] as String?,
      language: json['language'] as String? ?? 'Japanese',
    );
  }
}
