import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/explore/presentation/bloc/explore_bloc.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ScrollController _scrollController = ScrollController();

  static const _categories = [
    {'id': 'series', 'label': 'Seriler'},
    {'id': 'movie', 'label': 'Filmler'},
    {'id': 'trdub', 'label': 'Türkçe Dublaj'},
    {'id': 'genre', 'label': 'Türler'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ExploreBloc>().add(const LoadExploreCatalogRequested(kind: 'series'));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      context.read<ExploreBloc>().add(LoadNextExplorePageRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Keşfet',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (context, state) {
          final currentKind = (state is ExploreLoaded) ? state.kind : 'series';
          final currentGenreId = (state is ExploreLoaded) ? state.genreId : null;

          return Column(
            children: [
              // Category Tabs Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = currentKind == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: AppTypography.titleSmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            context.read<ExploreBloc>().add(
                                  ChangeExploreCategoryRequested(
                                    kind: cat['id']!,
                                    genreId: cat['id'] == 'genre'
                                        ? (currentGenreId ?? '62263')
                                        : null,
                                  ),
                                );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Genre Chips Row (Visible when 'genre' is selected)
              if (currentKind == 'genre') ...[
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    children: ApiConstants.genreIds.entries.map((entry) {
                      final isSelected = currentGenreId == entry.value.toString();
                      final cleanName = entry.key.replaceAll('_', ' ');

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(cleanName),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withAlpha(60),
                          checkmarkColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceDark,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (_) {
                            context.read<ExploreBloc>().add(
                                  ChangeExploreCategoryRequested(
                                    kind: 'genre',
                                    genreId: entry.value.toString(),
                                  ),
                                );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Content Grid
              Expanded(
                child: _buildContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ExploreState state) {
    if (state is ExploreLoading || state is ExploreInitial) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: 12,
        itemBuilder: (_, __) => const ShimmerPlaceholder(),
      );
    }

    if (state is ExploreFailureState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.accentCrimson,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(state.errorMessage, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ExploreBloc>().add(
                      const LoadExploreCatalogRequested(kind: 'series'),
                    );
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state is ExploreLoaded) {
      if (state.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Bu kategoride içerik bulunamadı',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<ExploreBloc>().add(
                ChangeExploreCategoryRequested(
                  kind: state.kind,
                  genreId: state.genreId,
                ),
              );
        },
        child: GridView.builder(
          controller: _scrollController,
          cacheExtent: 600,
          addRepaintBoundaries: true,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: state.items.length + (state.isLoadingMore ? 3 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const ShimmerPlaceholder();
            }
            final anime = state.items[index];
            return AnimePosterCard(
              id: anime.id,
              title: anime.title,
              posterUrl: anime.posterUrl,
              rating: anime.rating,
              episodeBadge: anime.currentEpisode,
              onTap: () => context.go('/anime/${anime.id}'),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
