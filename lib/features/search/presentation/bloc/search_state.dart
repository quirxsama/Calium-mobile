part of 'search_bloc.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.results,
    required this.query,
    this.selectedGenreId,
    this.selectedType,
    this.page = 1,
    this.hasMore = true,
  });

  final List<AnimeEntity> results;
  final String query;
  final String? selectedGenreId;
  final String? selectedType;
  final int page;
  final bool hasMore;

  SearchLoaded copyWith({
    List<AnimeEntity>? results,
    String? query,
    String? selectedGenreId,
    String? selectedType,
    int? page,
    bool? hasMore,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      selectedGenreId: selectedGenreId ?? this.selectedGenreId,
      selectedType: selectedType ?? this.selectedType,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        results,
        query,
        selectedGenreId,
        selectedType,
        page,
        hasMore,
      ];
}

final class SearchFailureState extends SearchState {
  const SearchFailureState({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
