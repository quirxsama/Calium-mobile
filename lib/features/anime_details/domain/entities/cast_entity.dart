import 'package:equatable/equatable.dart';

class CastEntity extends Equatable {
  const CastEntity({
    required this.id,
    required this.characterName,
    this.characterImageUrl,
    this.voiceActorName,
    this.voiceActorImageUrl,
    this.language = 'Japanese',
  });

  final int id;
  final String characterName;
  final String? characterImageUrl;
  final String? voiceActorName;
  final String? voiceActorImageUrl;
  final String language;

  @override
  List<Object?> get props => [
        id,
        characterName,
        characterImageUrl,
        voiceActorName,
        voiceActorImageUrl,
        language,
      ];
}
