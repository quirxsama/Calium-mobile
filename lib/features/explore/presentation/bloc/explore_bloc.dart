import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/explore/domain/usecases/get_explore_catalog_usecase.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

// ─── Events ─────────────────────────────────────────────────────

sealed class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

final class LoadExploreCatalogRequested extends ExploreEvent {
  const LoadExploreCatalogRequested({
    this.kind = 'series',
    this.genreId,
  });

  final String kind;
  final String? genreId;

  @override
  List<Object?> get props => [kind, genreId];
}

final class ChangeExploreCategoryRequested extends ExploreEvent {
  const ChangeExploreCategoryRequested({
    required this.kind,
    this.genreId,
  });

  final String kind;
  final String? genreId;

  @override
  List<Object?> get props => [kind, genreId];
}

final class LoadNextExplorePageRequested extends ExploreEvent {}

// ─── States ─────────────────────────────────────────────────────

sealed class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

final class ExploreInitial extends ExploreState {}

final class ExploreLoading extends ExploreState {}

final class ExploreLoaded extends ExploreState {
  const ExploreLoaded({
    required this.items,
    required this.kind,
    this.genreId,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<AnimeEntity> items;
  final String kind;
  final String? genreId;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  ExploreLoaded copyWith({
    List<AnimeEntity>? items,
    String? kind,
    String? genreId,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ExploreLoaded(
      items: items ?? this.items,
      kind: kind ?? this.kind,
      genreId: genreId ?? this.genreId,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [items, kind, genreId, page, hasMore, isLoadingMore];
}

final class ExploreFailureState extends ExploreState {
  const ExploreFailureState({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

// ─── BLoC ───────────────────────────────────────────────────────

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({required this._getExploreCatalogUseCase})
      :
        super(ExploreInitial()) {
    on<LoadExploreCatalogRequested>(_onLoad);
    on<ChangeExploreCategoryRequested>(_onChangeCategory);
    on<LoadNextExplorePageRequested>(_onLoadNextPage);
  }

  final GetExploreCatalogUseCase _getExploreCatalogUseCase;

  Future<void> _onLoad(
    LoadExploreCatalogRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());

    final result = await _getExploreCatalogUseCase(
      GetExploreCatalogParams(
        kind: event.kind,
        genreId: event.genreId,
        page: 1,
      ),
    );

    result.fold(
      (failure) => emit(ExploreFailureState(errorMessage: failure.message)),
      (items) => emit(
        ExploreLoaded(
          items: items,
          kind: event.kind,
          genreId: event.genreId,
          page: 1,
          hasMore: items.isNotEmpty,
        ),
      ),
    );
  }

  Future<void> _onChangeCategory(
    ChangeExploreCategoryRequested event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());

    final result = await _getExploreCatalogUseCase(
      GetExploreCatalogParams(
        kind: event.kind,
        genreId: event.genreId,
        page: 1,
      ),
    );

    result.fold(
      (failure) => emit(ExploreFailureState(errorMessage: failure.message)),
      (items) => emit(
        ExploreLoaded(
          items: items,
          kind: event.kind,
          genreId: event.genreId,
          page: 1,
          hasMore: items.isNotEmpty,
        ),
      ),
    );
  }

  Future<void> _onLoadNextPage(
    LoadNextExplorePageRequested event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final curr = state as ExploreLoaded;
    if (curr.isLoadingMore || !curr.hasMore) return;

    emit(curr.copyWith(isLoadingMore: true));

    final nextPage = curr.page + 1;
    final result = await _getExploreCatalogUseCase(
      GetExploreCatalogParams(
        kind: curr.kind,
        genreId: curr.genreId,
        page: nextPage,
      ),
    );

    result.fold(
      (failure) => emit(curr.copyWith(isLoadingMore: false)),
      (newItems) {
        if (newItems.isEmpty) {
          emit(curr.copyWith(hasMore: false, isLoadingMore: false));
        } else {
          emit(
            curr.copyWith(
              items: [...curr.items, ...newItems],
              page: nextPage,
              hasMore: true,
              isLoadingMore: false,
            ),
          );
        }
      },
    );
  }
}
