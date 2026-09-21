import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/home/presentation/bloc/home_bloc.dart';
import 'package:calium_stream/features/home/presentation/widgets/anime_rail.dart';
import 'package:calium_stream/features/home/presentation/widgets/continue_watching_section.dart';
import 'package:calium_stream/features/home/presentation/widgets/hero_carousel.dart';
import 'package:calium_stream/features/home/presentation/widgets/random_anime_card.dart';
import 'package:calium_stream/features/home/presentation/widgets/top_ranked_rail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _refresh() async {
    final bloc = context.read<HomeBloc>();
    final completed = bloc.stream.firstWhere(
      (state) =>
          state is HomeFailureState ||
          (state is HomeLoaded && !state.isRefreshing),
    );
    bloc.add(RefreshHomeFeedRequested());
    await completed;
  }

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
            return _buildOfflineDashboard(context, isNetwork: state.isNetwork);
          }

          if (state is HomeLoaded) {
            if ([
              state.trending,
              state.topRanked,
              state.topAiring,
              state.seasonal,
              state.trDub,
              state.action,
              state.isekai,
              state.movies,
              state.continueWatching,
            ].every((items) => items.isEmpty)) {
              return _buildOfflineDashboard(context, isEmpty: true);
            }

            final allForRandom = [
              ...state.trending,
              ...state.topRanked,
              ...state.action,
              ...state.isekai,
            ];

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              onRefresh: _refresh,
              child: CustomScrollView(
                scrollCacheExtent: ScrollCacheExtent.pixels(800),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Solid navigation keeps the featured artwork in focus.
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    toolbarHeight: 72,
                    flexibleSpace: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo
                            Flexible(
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/icon.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'CALIUM',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.headlineLarge
                                          .copyWith(
                                            color: AppColors.primary,
                                            letterSpacing: 1.5,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Anime ara',
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.textPrimary,
                                  ),
                                  onPressed: () => context.go('/search'),
                                ),
                                IconButton(
                                  tooltip: 'Profilim',
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

                  if (state.refreshError.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.refreshError,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: state.isRefreshing ? null : _refresh,
                              child: const Text('Yeniden dene'),
                            ),
                          ],
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
                      height: 32 + MediaQuery.textScalerOf(context).scale(16),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
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
                  const SliverToBoxAdapter(child: ContinueWatchingSection()),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

  Widget _buildOfflineDashboard(
    BuildContext context, {
    bool isNetwork = false,
    bool isEmpty = false,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 64,
        title: const Text(
          'CALIUM',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'İndirmeler',
            icon: const Icon(Icons.download_for_offline_rounded),
            onPressed: () => context.push('/downloads'),
          ),
        ],
      ),
      body: StreamBuilder<List<DownloadTaskEntity>>(
        stream: DownloadService.instance.tasksStream,
        initialData: DownloadService.instance.currentTasks,
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final completedTasks = allTasks
              .where((t) => t.status == DownloadStatus.completed)
              .toList();

          // Group completed tasks by anime
          final Map<String, List<DownloadTaskEntity>> animeGroups = {};
          for (final t in completedTasks) {
            animeGroups.putIfAbsent(t.animeId, () => []).add(t);
          }
          final downloadedAnimeList = animeGroups.values.toList();

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceElevated,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Offline Header Banner ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusLg,
                      ),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentCrimson.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isNetwork
                                ? Icons.wifi_off_rounded
                                : Icons.info_outline_rounded,
                            color: AppColors.accentCrimson,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEmpty
                                    ? 'Henüz içerik bulunamadı'
                                    : isNetwork
                                    ? 'Bağlantı kurulamadı'
                                    : 'Ana sayfa yüklenemedi',
                                style: AppTypography.headlineMedium.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                completedTasks.isNotEmpty
                                    ? 'İndirdiğiniz ${completedTasks.length} bölümü çevrimdışı izleyebilir veya akışı yeniden yükleyebilirsiniz.'
                                    : isEmpty
                                    ? 'İçerik listesi boş döndü. Biraz sonra yeniden deneyebilirsiniz.'
                                    : 'Akış alınamadı. Yeniden deneyebilir veya indirmelerinize gidebilirsiniz.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Downloaded Animes Shelf (if any available) ─────────────
                  if (downloadedAnimeList.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'İndirilen İçerikleriniz',
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/downloads'),
                          child: const Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: downloadedAnimeList.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final tasks = downloadedAnimeList[index];
                          final firstTask = tasks.first;

                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/watch/${firstTask.animeId}?title=${Uri.encodeComponent(firstTask.animeTitle)}&episode=${Uri.encodeComponent(firstTask.episodeTitle)}&s=${firstTask.seasonNumber}&ep=${firstTask.episodeNumber}&poster=${Uri.encodeComponent(firstTask.posterUrl)}&url=${Uri.encodeComponent(firstTask.savePath)}',
                              );
                            },
                            child: SizedBox(
                              width: 130,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.borderRadiusMd,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          firstTask
                                                      .localPosterPath
                                                      .isNotEmpty &&
                                                  File(
                                                    firstTask.localPosterPath,
                                                  ).existsSync()
                                              ? Image.file(
                                                  File(
                                                    firstTask.localPosterPath,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : AppCachedImage(
                                                  imageUrl: firstTask.posterUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                          Positioned(
                                            bottom: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.black,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    firstTask.animeTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${tasks.length} Bölüm Hazır',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // ── Action Buttons ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/downloads'),
                      icon: const Icon(
                        Icons.download_for_offline_rounded,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'İndirilenleri Yönet',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Tekrar Bağlanmayı Dene',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
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
