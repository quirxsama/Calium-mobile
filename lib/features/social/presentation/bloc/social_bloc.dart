import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/social/domain/entities/app_notification_entity.dart';
import 'package:calium_stream/features/social/domain/entities/follow_request_entity.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';
import 'package:calium_stream/features/social/domain/repositories/social_repository.dart';

// ─── Events ─────────────────────────────────────────────────────

sealed class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

final class LoadSocialDataRequested extends SocialEvent {}

final class SwitchSocialTabRequested extends SocialEvent {
  const SwitchSocialTabRequested(this.tabIndex);
  final int tabIndex;

  @override
  List<Object?> get props => [tabIndex];
}

final class JoinRoomByCodeRequested extends SocialEvent {
  const JoinRoomByCodeRequested(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

final class CreateRoomRequested extends SocialEvent {
  const CreateRoomRequested({
    required this.animeId,
    required this.animeName,
    required this.episodeId,
    this.episodeName,
    this.poster,
    this.isPublic = true,
  });

  final String animeId;
  final String animeName;
  final String episodeId;
  final String? episodeName;
  final String? poster;
  final bool isPublic;

  @override
  List<Object?> get props => [
    animeId,
    animeName,
    episodeId,
    episodeName,
    poster,
    isPublic,
  ];
}

final class CloseRoomRequested extends SocialEvent {
  const CloseRoomRequested(this.roomId);
  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

final class LeaveRoomRequested extends SocialEvent {
  const LeaveRoomRequested(this.roomId);
  final String roomId;

  @override
  List<Object?> get props => [roomId];
}

final class RespondFollowRequestRequested extends SocialEvent {
  const RespondFollowRequestRequested({
    required this.username,
    required this.accept,
  });

  final String username;
  final bool accept;

  @override
  List<Object?> get props => [username, accept];
}

final class MarkNotificationsReadRequested extends SocialEvent {}

final class ClearNotificationsRequested extends SocialEvent {}

// ─── States ─────────────────────────────────────────────────────

sealed class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

final class SocialInitial extends SocialState {}

final class SocialLoading extends SocialState {}

final class SocialLoaded extends SocialState {
  const SocialLoaded({
    required this.rooms,
    required this.myRooms,
    required this.friends,
    this.followRequests = const [],
    this.notifications = const [],
    this.selectedTab = 0,
  });

  final List<RoomEntity> rooms;
  final List<RoomEntity> myRooms;
  final List<SocialFriendEntity> friends;
  final List<FollowRequestEntity> followRequests;
  final List<AppNotificationEntity> notifications;
  final int selectedTab;

  int get unreadNotificationCount =>
      notifications.where((n) => n.isUnread).length;

  int get totalBadgeCount => followRequests.length + unreadNotificationCount;

  SocialLoaded copyWith({
    List<RoomEntity>? rooms,
    List<RoomEntity>? myRooms,
    List<SocialFriendEntity>? friends,
    List<FollowRequestEntity>? followRequests,
    List<AppNotificationEntity>? notifications,
    int? selectedTab,
  }) {
    return SocialLoaded(
      rooms: rooms ?? this.rooms,
      myRooms: myRooms ?? this.myRooms,
      friends: friends ?? this.friends,
      followRequests: followRequests ?? this.followRequests,
      notifications: notifications ?? this.notifications,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  @override
  List<Object?> get props => [
    rooms,
    myRooms,
    friends,
    followRequests,
    notifications,
    selectedTab,
  ];
}

final class SocialRoomJoinedState extends SocialState {
  const SocialRoomJoinedState({required this.room});
  final RoomEntity room;

  @override
  List<Object?> get props => [room];
}

final class SocialFailureState extends SocialState {
  const SocialFailureState({required this.errorMessage});
  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

// ─── BLoC ───────────────────────────────────────────────────────

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  SocialBloc({required this._repository}) : super(SocialInitial()) {
    on<LoadSocialDataRequested>(_onLoad);
    on<SwitchSocialTabRequested>(_onSwitchTab);
    on<JoinRoomByCodeRequested>(_onJoinCode);
    on<CreateRoomRequested>(_onCreateRoom);
    on<CloseRoomRequested>(_onCloseRoom);
    on<LeaveRoomRequested>(_onLeaveRoom);
    on<RespondFollowRequestRequested>(_onRespondFollowRequest);
    on<MarkNotificationsReadRequested>(_onMarkNotificationsRead);
    on<ClearNotificationsRequested>(_onClearNotifications);
  }

  final SocialRepository _repository;

  Future<void> _onLoad(
    LoadSocialDataRequested event,
    Emitter<SocialState> emit,
  ) async {
    final currentTab = (state is SocialLoaded)
        ? (state as SocialLoaded).selectedTab
        : 0;
    emit(SocialLoading());

    final roomsResult = await _repository.getPublicRooms();
    final myRoomsResult = await _repository.getMyRooms();
    final friendsResult = await _repository.getFriends();
    final requestsResult = await _repository.getFollowRequests();
    final notifsResult = await _repository.getNotifications();

    final rooms = roomsResult.getOrElse(() => []);
    final myRooms = myRoomsResult.getOrElse(() => []);
    final friends = friendsResult.getOrElse(() => []);
    final followRequests = requestsResult.getOrElse(() => []);
    final notifications = notifsResult.getOrElse(() => []);

    emit(
      SocialLoaded(
        rooms: rooms,
        myRooms: myRooms,
        friends: friends,
        followRequests: followRequests,
        notifications: notifications,
        selectedTab: currentTab,
      ),
    );
  }

  void _onSwitchTab(SwitchSocialTabRequested event, Emitter<SocialState> emit) {
    if (state is SocialLoaded) {
      emit((state as SocialLoaded).copyWith(selectedTab: event.tabIndex));
    }
  }

  Future<void> _onJoinCode(
    JoinRoomByCodeRequested event,
    Emitter<SocialState> emit,
  ) async {
    final result = await _repository.joinRoomByCode(event.code);
    result.fold(
      (failure) => emit(SocialFailureState(errorMessage: failure.message)),
      (room) => emit(SocialRoomJoinedState(room: room)),
    );
  }

  Future<void> _onCreateRoom(
    CreateRoomRequested event,
    Emitter<SocialState> emit,
  ) async {
    final result = await _repository.createRoom(
      animeId: event.animeId,
      animeName: event.animeName,
      episodeId: event.episodeId,
      episodeName: event.episodeName,
      poster: event.poster,
      isPublic: event.isPublic,
    );
    result.fold(
      (failure) => emit(SocialFailureState(errorMessage: failure.message)),
      (room) {
        emit(SocialRoomJoinedState(room: room));
        add(LoadSocialDataRequested());
      },
    );
  }

  Future<void> _onCloseRoom(
    CloseRoomRequested event,
    Emitter<SocialState> emit,
  ) async {
    final result = await _repository.closeRoom(event.roomId);
    result.fold(
      (failure) => emit(SocialFailureState(errorMessage: failure.message)),
      (_) => add(LoadSocialDataRequested()),
    );
  }

  Future<void> _onLeaveRoom(
    LeaveRoomRequested event,
    Emitter<SocialState> emit,
  ) async {
    final result = await _repository.leaveRoom(event.roomId);
    result.fold(
      (failure) => emit(SocialFailureState(errorMessage: failure.message)),
      (_) => add(LoadSocialDataRequested()),
    );
  }

  Future<void> _onRespondFollowRequest(
    RespondFollowRequestRequested event,
    Emitter<SocialState> emit,
  ) async {
    if (state is SocialLoaded) {
      final current = state as SocialLoaded;
      final updatedRequests = current.followRequests
          .where((r) => r.username != event.username)
          .toList();
      emit(current.copyWith(followRequests: updatedRequests));
    }

    await _repository.respondFollowRequest(
      username: event.username,
      accept: event.accept,
    );
    add(LoadSocialDataRequested());
  }

  Future<void> _onMarkNotificationsRead(
    MarkNotificationsReadRequested event,
    Emitter<SocialState> emit,
  ) async {
    await _repository.markNotificationsRead();
    if (state is SocialLoaded) {
      final current = state as SocialLoaded;
      final updated = current.notifications.map((n) {
        return AppNotificationEntity(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          avatarUrl: n.avatarUrl,
          actorUsername: n.actorUsername,
          animeId: n.animeId,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }).toList();
      emit(current.copyWith(notifications: updated));
    }
  }

  Future<void> _onClearNotifications(
    ClearNotificationsRequested event,
    Emitter<SocialState> emit,
  ) async {
    await _repository.clearAllNotifications();
    if (state is SocialLoaded) {
      final current = state as SocialLoaded;
      emit(current.copyWith(notifications: const []));
    }
  }
}
