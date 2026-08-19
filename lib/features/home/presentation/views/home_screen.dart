import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/home/presentation/bloc/home_bloc.dart';
import 'package:calium_stream/features/home/presentation/widgets/anime_rail.dart';
import 'package:calium_stream/features/home/presentation/widgets/continue_watching_section.dart';
import 'package:calium_stream/features/home/presentation/widgets/hero_carousel.dart';
import 'package:calium_stream/features/home/presentation/widgets/random_anime_card.dart';
import 'package:calium_stream/features/home/presentation/widgets/top_ranked_rail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return _buildLoadingSkeleton();
          }

          if (state is HomeFailureState) {
            return _buildErrorView(context, state.errorMessage);
          }

          if (state is HomeLoaded) {
            final allForRandom = [
              ...state.trending,
              ...state.topRanked,
              ...state.action,
              ...state.isekai,
            ];

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshHomeFeedRequested());
              },
              child: CustomScrollView(
                cacheExtent: 800,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // ─── Glassmorphic Top App Bar ─────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 64,
                    flexibleSpace: GlassContainer(
                      borderRadius: 0,
                      blur: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.accentCrimson],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                                  ),
                                ),
                                Text(
                                  'CALIUM',
                                  style: AppTypography.headlineLarge.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.5,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),

                            // Actions
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () => context.go('/search'),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () => context.push('/profile'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),

                  // ─── Hero Carousel (Trending) ─────────────────────
                  if (state.trending.isNotEmpty)
                    SliverToBoxAdapter(
                      child: HeroCarousel(animes: state.trending),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),

                  // ─── Quick Discovery Shortcuts ────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                        children: [
                          _buildShortcutChip(
                            context: context,
                            icon: Icons.calendar_month_rounded,
                            label: 'Yayın Takvimi',
                            route: '/calendar',
                          ),
                          const SizedBox(width: 8),
                          _buildShortcutChip(
                            context: context,
                            icon: Icons.emoji_events_rounded,
                            label: 'Top 10',
                            route: '/top-anime',
                          ),
                          const SizedBox(width: 8),
                          _buildShortcutChip(
                            context: context,
                            icon: Icons.record_voice_over_rounded,
                            label: 'TR Dublaj',
                            route: '/tr-dub',
                          ),
                          const SizedBox(width: 8),
                          _buildShortcutChip(
                            context: context,
                            icon: Icons.playlist_play_rounded,
                            label: 'Listeler',
                            route: '/lists',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.lg),
                  ),

                  // ─── Continue Watching (Live Hive & Feed) ────────
                  const SliverToBoxAdapter(
                    child: ContinueWatchingSection(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),

                  // ─── Top 10 Ranked Rail (Stylized Big Numbers) ────
                  if (state.topRanked.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: TopRankedRail(
                        title: 'Top 10 Popüler Anime',
                        animes: state.topRanked,
                        onSeeAll: () => context.push('/top-anime'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Latest Episodes Rail ─────────────────────────
                  if (state.topAiring.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Son Çıkan Bölümler',
                        animes: state.topAiring,
                        onSeeAll: () => context.go('/explore'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Interactive Random Anime Card (Zar At) ───────
                  if (allForRandom.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: RandomAnimeCard(animes: allForRandom),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Turkish Dubbed Rail ──────────────────────────
                  if (state.trDub.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Türkçe Dublajlı Animeler',
                        animes: state.trDub,
                        onSeeAll: () => context.push('/tr-dub'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Action & Adventure Rail ──────────────────────
                  if (state.action.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Aksiyon & Macera',
                        animes: state.action,
                        onSeeAll: () => context.go('/explore'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Isekai & Fantasy Rail ────────────────────────
                  if (state.isekai.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Isekai & Fantastik Dünyalar',
                        animes: state.isekai,
                        onSeeAll: () => context.go('/explore'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Anime Movies Rail ────────────────────────────
                  if (state.movies.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Anime Filmleri (Sinema Keyfi)',
                        animes: state.movies,
                        onSeeAll: () => context.go('/explore'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // ─── Seasonal Hits Rail ───────────────────────────
                  if (state.seasonal.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: AnimeRail(
                        title: 'Popüler Anime Serileri',
                        animes: state.seasonal,
                        onSeeAll: () => context.go('/search'),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerPlaceholder(height: 200, borderRadius: 16),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: List.generate(
                3,
                (_) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ShimmerPlaceholder(height: 36, borderRadius: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const ShimmerPlaceholder(height: 24, width: 140),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: List.generate(
                3,
                (_) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: ShimmerPlaceholder(height: 180, borderRadius: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.accentCrimson,
              size: 54,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Çevrimdışısınız',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'İnternet bağlantısı kurulamadı. İndirdiğiniz bölümleri çevrimdışı izleyebilirsiniz.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/downloads'),
                icon: const Icon(Icons.download_for_offline_rounded, color: Colors.black),
                label: const Text('İndirilenleri İzle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                context.read<HomeBloc>().add(LoadHomeFeedRequested());
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
