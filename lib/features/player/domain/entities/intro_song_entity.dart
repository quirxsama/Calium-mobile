import 'package:equatable/equatable.dart';

/// Represents recognized intro song metadata for an anime episode.
class IntroSongEntity extends Equatable {
  const IntroSongEntity({
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.spotifyUrl,
  });

  final String title;
  final String artist;
  final String? coverUrl;
  final String spotifyUrl;

  @override
  List<Object?> get props => [title, artist, coverUrl, spotifyUrl];
}
