import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class HomeFeedEntity extends Equatable {
  const HomeFeedEntity({
    required this.trending,
    required this.topAiring,
    required this.seasonal,
    this.topRanked = const [],
    this.trDub = const [],
    this.action = const [],
    this.isekai = const [],
    this.movies = const [],
    this.continueWatching = const [],
  });

  final List<AnimeEntity> trending;
  final List<AnimeEntity> topAiring;
  final List<AnimeEntity> seasonal;
  final List<AnimeEntity> topRanked;
  final List<AnimeEntity> trDub;
  final List<AnimeEntity> action;
  final List<AnimeEntity> isekai;
  final List<AnimeEntity> movies;
  final List<AnimeEntity> continueWatching;

  @override
  List<Object?> get props => [
        trending,
        topAiring,
        seasonal,
        topRanked,
        trDub,
        action,
        isekai,
        movies,
        continueWatching,
      ];
}
