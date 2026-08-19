import 'package:equatable/equatable.dart';

class FavoriteEntity extends Equatable {
  const FavoriteEntity({
    required this.animeId,
    required this.name,
    required this.posterUrl,
    required this.addedAt,
  });

  final String animeId;
  final String name;
  final String posterUrl;
  final DateTime addedAt;

  @override
  List<Object?> get props => [animeId, name, posterUrl, addedAt];
}
