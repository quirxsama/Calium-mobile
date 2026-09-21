import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/adaptive_poster_grid.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/search/presentation/bloc/search_bloc.dart';
import 'package:calium_stream/features/search/presentation/widgets/filter_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initial fetch of popular animes if search is empty
    context.read<SearchBloc>().add(const SearchQueryChanged(query: ''));

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<SearchBloc>().add(SearchNextPageRequested());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openFilters(SearchLoaded? state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initialGenreId: state?.selectedGenreId,
        initialType: state?.selectedType,
        onApply: (genreId, type) {
          context.read<SearchBloc>().add(
            SearchFilterApplied(genreId: genreId, type: type),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Filter Bar ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (query) {
                        setState(() {});
                        context.read<SearchBloc>().add(
                          SearchQueryChanged(query: query),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Anime ara...',
                        hintStyle: AppTypography.bodyMedium,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Aramayı temizle',
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                  context.read<SearchBloc>().add(
                                    const SearchQueryChanged(query: ''),
                                  );
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Filter Button
                  BlocBuilder<SearchBloc, SearchState>(
                    builder: (context, state) {
                      final loaded = state is SearchLoaded ? state : null;
                      final hasActiveFilters =
                          loaded?.selectedGenreId != null ||
                          loaded?.selectedType != null;

                      return IconButton.filled(
                        tooltip: 'Arama filtreleri',
                        onPressed: () => _openFilters(loaded),
                        icon: Icon(
                          hasActiveFilters
                              ? Icons.filter_alt_rounded
                              : Icons.tune_rounded,
                          color: hasActiveFilters
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          padding: const EdgeInsets.all(12),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Search Results Grid ─────────────────────────────────
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return _buildGridSkeleton();
                  }

                  if (state is SearchFailureState) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(state.message, style: AppTypography.bodyMedium),
                        ],
                      ),
                    );
                  }

                  if (state is SearchLoaded) {
                    if (state.results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.movie_filter_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Sonuç bulunamadı',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Farklı bir kelime veya filtre deneyin.',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return AdaptivePosterGrid(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final anime = state.results[index];
                        return AnimePosterCard(
                          id: anime.id,
                          title: anime.title,
                          posterUrl: anime.posterUrl,
                          rating: anime.rating,
                          episodeBadge: anime.currentEpisode,
                          onTap: () => context.go('/anime/${anime.id}'),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return AdaptivePosterGrid(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerPlaceholder(borderRadius: 12)),
          SizedBox(height: 6),
          ShimmerPlaceholder(width: 80, height: 12),
        ],
      ),
    );
  }
}
