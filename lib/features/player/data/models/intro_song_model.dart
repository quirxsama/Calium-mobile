import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';

class IntroSongModel extends IntroSongEntity {
  const IntroSongModel({
    required super.title,
    required super.artist,
    super.coverUrl,
    required super.spotifyUrl,
  });

  factory IntroSongModel.fromJson(Map<String, dynamic> json) {
    return IntroSongModel(
      title: (json['title'] as String?)?.trim() ?? '',
      artist: (json['artist'] as String?)?.trim() ?? '',
      coverUrl: json['coverUrl'] as String?,
      spotifyUrl: (json['spotifyUrl'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'spotifyUrl': spotifyUrl,
    };
  }
}
