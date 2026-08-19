import 'package:dartz/dartz.dart';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';

abstract class SocialRepository {
  Future<Either<Failure, List<RoomEntity>>> getPublicRooms();
  Future<Either<Failure, List<RoomEntity>>> getMyRooms();
  Future<Either<Failure, RoomEntity>> joinRoomByCode(String code);
  Future<Either<Failure, RoomEntity>> createRoom({
    required String animeId,
    required String animeName,
    required String episodeId,
    String? episodeName,
    String? poster,
    bool isPublic = true,
  });
  Future<Either<Failure, void>> closeRoom(String roomId);
  Future<Either<Failure, void>> leaveRoom(String roomId);
  Future<Either<Failure, List<SocialFriendEntity>>> getFriends();
}

