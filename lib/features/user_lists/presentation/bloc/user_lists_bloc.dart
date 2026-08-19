import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';
import 'package:calium_stream/features/user_lists/domain/repositories/user_lists_repository.dart';

// ─── Events ──────────────────────────────────────────────────
sealed class UserListsEvent extends Equatable {
  const UserListsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadUserListsRequested extends UserListsEvent {}

final class CreateUserListRequested extends UserListsEvent {
  const CreateUserListRequested({
    required this.name,
    this.description,
    this.isPublic = true,
  });

  final String name;
  final String? description;
  final bool isPublic;

  @override
  List<Object?> get props => [name, description, isPublic];
}

final class AddAnimeToListRequested extends UserListsEvent {
  const AddAnimeToListRequested({
    required this.listId,
    required this.animeId,
    required this.animeName,
    this.poster,
  });

  final String listId;
  final String animeId;
  final String animeName;
  final String? poster;

  @override
  List<Object?> get props => [listId, animeId, animeName, poster];
}

final class RemoveAnimeFromListRequested extends UserListsEvent {
  const RemoveAnimeFromListRequested({
    required this.listId,
    required this.animeId,
  });

  final String listId;
  final String animeId;

  @override
  List<Object?> get props => [listId, animeId];
}

final class ToggleLikeListRequested extends UserListsEvent {
  const ToggleLikeListRequested(this.listId);

  final String listId;

  @override
  List<Object?> get props => [listId];
}

// ─── States ──────────────────────────────────────────────────
sealed class UserListsState extends Equatable {
  const UserListsState();

  @override
  List<Object?> get props => [];
}

final class UserListsInitial extends UserListsState {}

final class UserListsLoading extends UserListsState {}

final class UserListsLoaded extends UserListsState {
  const UserListsLoaded({
    required this.myLists,
    required this.publicLists,
  });

  final List<UserListEntity> myLists;
  final List<UserListEntity> publicLists;

  @override
  List<Object?> get props => [myLists, publicLists];
}

final class UserListsFailure extends UserListsState {
  const UserListsFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────
class UserListsBloc extends Bloc<UserListsEvent, UserListsState> {
  UserListsBloc({required UserListsRepository repository})
      : _repository = repository,
        super(UserListsInitial()) {
    on<LoadUserListsRequested>(_onLoadUserLists);
    on<CreateUserListRequested>(_onCreateUserList);
    on<AddAnimeToListRequested>(_onAddAnimeToList);
    on<RemoveAnimeFromListRequested>(_onRemoveAnimeFromList);
    on<ToggleLikeListRequested>(_onToggleLikeList);
  }

  final UserListsRepository _repository;

  Future<void> _onLoadUserLists(
    LoadUserListsRequested event,
    Emitter<UserListsState> emit,
  ) async {
    emit(UserListsLoading());

    final myRes = await _repository.getMyLists();
    final pubRes = await _repository.getPublicLists();

    List<UserListEntity> myLists = [];
    List<UserListEntity> pubLists = [];

    myRes.fold((_) => null, (l) => myLists = l);
    pubRes.fold((_) => null, (l) => pubLists = l);

    emit(UserListsLoaded(myLists: myLists, publicLists: pubLists));
  }

  Future<void> _onCreateUserList(
    CreateUserListRequested event,
    Emitter<UserListsState> emit,
  ) async {
    final res = await _repository.createList(
      name: event.name,
      description: event.description,
      isPublic: event.isPublic,
    );
    res.fold(
      (f) => emit(UserListsFailure(message: f.message)),
      (_) => add(LoadUserListsRequested()),
    );
  }

  Future<void> _onAddAnimeToList(
    AddAnimeToListRequested event,
    Emitter<UserListsState> emit,
  ) async {
    await _repository.addAnimeToList(
      listId: event.listId,
      animeId: event.animeId,
      animeName: event.animeName,
      poster: event.poster,
    );
    add(LoadUserListsRequested());
  }

  Future<void> _onRemoveAnimeFromList(
    RemoveAnimeFromListRequested event,
    Emitter<UserListsState> emit,
  ) async {
    await _repository.removeAnimeFromList(
      listId: event.listId,
      animeId: event.animeId,
    );
    add(LoadUserListsRequested());
  }

  Future<void> _onToggleLikeList(
    ToggleLikeListRequested event,
    Emitter<UserListsState> emit,
  ) async {
    await _repository.toggleLikeList(event.listId);
    add(LoadUserListsRequested());
  }
}
