part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SearchFilterApplied extends SearchEvent {
  const SearchFilterApplied({
    this.genreId,
    this.type,
  });

  final String? genreId;
  final String? type;

  @override
  List<Object?> get props => [genreId, type];
}

final class SearchNextPageRequested extends SearchEvent {}
