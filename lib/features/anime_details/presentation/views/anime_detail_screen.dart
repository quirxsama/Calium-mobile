import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_cast_usecase.dart';
import 'package:calium_stream/features/anime_details/presentation/bloc/anime_detail_bloc.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/cast_carousel.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/episode_detail_sheet.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/episode_list_widget.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/user_lists/presentation/widgets/add_to_list_bottom_sheet.dart';


class AnimeDetailScreen extends StatelessWidget {
  const AnimeDetailScreen({
    required this.animeId,
    super.key,
  });

  final String animeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnimeDetailBloc(
        getAnimeDetailUseCase: GetIt.I<GetAnimeDetailUseCase>(),
        getCastUseCase: GetIt.I<GetCastUseCase>(),
        repository: GetIt.I<AnimeDetailRepository>(),
      )..add(LoadAnimeDetailRequested(animeId: animeId)),
      child: const _AnimeDetailView(),
    );
  }
}

class _AnimeDetailView extends StatefulWidget {
  const _AnimeDetailView();

  @override
  State<_AnimeDetailView> createState() => _AnimeDetailViewState();
}

class _AnimeDetailViewState extends State<_AnimeDetailView> {
  static final Map<String, Color> _paletteCache = {};

  bool _isSynopsisExpanded = false;
  Color _dynamicAccentColor = AppColors.primary;
  Color _dynamicGlowColor = Colors.transparent;
  String? _lastExtractedPoster;

  void _extractPalette(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || _lastExtractedPoster == imageUrl) return;
    _lastExtractedPoster = imageUrl;

    final fullUrl = imageUrl.startsWith('http') ? imageUrl : 'https://calium.fun$imageUrl';

    // 1. Check in-memory cache for instant 0ms coloring
    if (_paletteCache.containsKey(fullUrl)) {
      final cachedColor = _paletteCache[fullUrl]!;
      _dynamicAccentColor = cachedColor;
      _dynamicGlowColor = cachedColor.withAlpha(70);
      return;
    }

    // 2. Fast downsampled palette extraction (64x64, 8 colors)
    PaletteGenerator.fromImageProvider(
      CachedNetworkImageProvider(fullUrl),
      size: const Size(64, 64),
      maximumColorCount: 8,
    ).then((palette) {
      if (!mounted) return;
      final dominant = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.lightVibrantColor?.color ??
          AppColors.primary;

      _paletteCache[fullUrl] = dominant;

      setState(() {
        _dynamicAccentColor = dominant;
        _dynamicGlowColor = dominant.withAlpha(70);
      });
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: AppColors.background,
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.65),
            radius: 1.15,
            colors: [
              _dynamicGlowColor,
              AppColors.background.withAlpha(245),
              AppColors.background,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: BlocBuilder<AnimeDetailBloc, AnimeDetailState>(
          builder: (context, state) {
            if (state is AnimeDetailLoading || state is AnimeDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is AnimeDetailFailureState) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.accentCrimson,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message, style: AppTypography.bodyMedium),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Geri Dön'),
                    ),
                  ],
                ),
              );
            }

            if (state is AnimeDetailLoaded) {
              final detail = state.detail;
              final bannerImage = detail.bannerUrl ?? detail.posterUrl;
              _extractPalette(detail.posterUrl);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Hero Banner Header ──────────────────────────────
                  SliverAppBar(
                    expandedHeight: 340,
                    pinned: true,
                    backgroundColor: AppColors.background,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GlassContainer(
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background banner
                        AppCachedImage(
                          imageUrl: bannerImage,
                          fit: BoxFit.cover,
                        ),

                        // Gradient Scrim
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background.withAlpha(160),
                                AppColors.background,
                              ],
                              stops: const [0.2, 0.7, 1.0],
                            ),
                          ),
                        ),

                        // Poster & Title Info at bottom of header
                        Positioned(
                          left: AppSpacing.screenPadding,
                          right: AppSpacing.screenPadding,
                          bottom: AppSpacing.lg,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Hero Poster
                              Hero(
                                tag: 'anime-poster-${detail.id}',
                                child: AppCachedImage(
                                  imageUrl: detail.posterUrl,
                                  width: 100,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusMd,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (detail.rating != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.ratingAmber,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            detail.rating!.toStringAsFixed(1),
                                            style: AppTypography.titleSmall
                                                .copyWith(
                                              color: AppColors.ratingAmber,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (detail.year != null) ...[
                                            Text(
                                              ' • ${detail.year}',
                                              style: AppTypography.bodySmall,
                                            ),
                                          ],
                                          if (detail.status != null) ...[
                                            Text(
                                              ' • ${detail.status}',
                                              style: AppTypography.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      detail.title,
                                      style:
                                          AppTypography.headlineMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (detail.originalTitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        detail.originalTitle!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Quick Action Dock ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Play Button with Resume Support
                        ValueListenableBuilder(
                          valueListenable: Hive.box('history').listenable(),
                          builder: (context, Box box, _) {
                            final saved = box.get(detail.id);
                            int targetSeason = state.selectedSeason;
                            int targetEp = 1;
                            String targetEpTitle = 'Bölüm 1';
                            String targetEpId = '';
                            bool hasHistory = false;

                            if (saved is Map) {
                              final sNum = int.tryParse(saved['seasonNumber']?.toString() ?? '');
                              final epNum = int.tryParse(saved['episodeNumber']?.toString() ?? '');
                              if (epNum != null && epNum > 0) {
                                targetSeason = sNum ?? targetSeason;
                                targetEp = epNum;
                                targetEpTitle = saved['episodeName']?.toString() ?? 'Bölüm $epNum';
                                final sId = saved['episodeId']?.toString() ?? '';
                                if (sId.isNotEmpty && !sId.contains('_')) {
                                  targetEpId = sId;
                                }
                                hasHistory = true;
                              }
                            }

                            if (!hasHistory && state.episodes.isNotEmpty) {
                              final firstEp = state.episodes.first;
                              targetEp = firstEp.episodeNumber;
                              targetEpTitle = firstEp.title ?? 'Bölüm ${firstEp.episodeNumber}';
                              targetEpId = firstEp.id;
                            } else if (targetEpId.isEmpty && state.episodes.isNotEmpty) {
                              final matched = state.episodes.where(
                                (e) => e.seasonNumber == targetSeason && e.episodeNumber == targetEp,
                              );
                              if (matched.isNotEmpty && matched.first.id.isNotEmpty && !matched.first.id.contains('_')) {
                                targetEpId = matched.first.id;
                              }
                            }

                            final buttonLabel = hasHistory
                                ? 'Devam Et (Bölüm $targetEp)'
                                : 'İzle';

                            return Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push(
                                    '/watch/${detail.id}?url=&title=${Uri.encodeComponent(detail.title)}&episode=${Uri.encodeComponent(targetEpTitle)}&ep=$targetEp&s=$targetSeason&poster=${Uri.encodeComponent(detail.posterUrl)}&episodeId=${Uri.encodeComponent(targetEpId)}',
                                  );
                                },
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 24,
                                ),
                                label: Text(
                                  buttonLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dynamicAccentColor,
                                  foregroundColor: _dynamicAccentColor.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.borderRadiusMd,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Favorite (Heart) Button
                        BlocBuilder<LibraryBloc, LibraryState>(
                          builder: (context, libraryState) {
                            final favorites = libraryState is LibraryLoaded
                                ? libraryState.favorites
                                : const <FavoriteEntity>[];
                            final isFavorite = favorites
                                .any((f) => f.animeId == detail.id);
                            return IconButton.filled(
                              tooltip: isFavorite
                                  ? 'Favorilerden Çıkar'
                                  : 'Favorilere Ekle',
                              onPressed: () {
                                context.read<LibraryBloc>().add(
                                      ToggleFavoriteRequested(
                                        favorite: FavoriteEntity(
                                          animeId: detail.id,
                                          name: detail.title,
                                          posterUrl: detail.posterUrl,
                                          addedAt: DateTime.now(),
                                        ),
                                      ),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                    content: Text(
                                      isFavorite
                                          ? 'Favorilerden çıkarıldı'
                                          : 'Favorilere eklendi',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFavorite
                                    ? AppColors.accentCrimson
                                    : AppColors.textPrimary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surfaceElevated,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.all(14),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // Custom List Button
                        IconButton.filled(
                          tooltip: 'Özel Listeye Ekle',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (_) => AddToListBottomSheet(
                                animeId: detail.id,
                                animeName: detail.title,
                                poster: detail.posterUrl,
                              ),
                            );
                          },
                          icon: const Icon(Icons.playlist_add_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceElevated,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // Download Episode Button
                        IconButton.filled(
                          tooltip: 'Bölümü İndir',
                          onPressed: () {
                            if (state.episodes.isNotEmpty) {
                              final firstEp = state.episodes.first;
                              DownloadService.instance.addTask(
                                animeId: detail.id,
                                animeTitle: detail.title,
                                episodeTitle: firstEp.title ?? 'Bölüm ${firstEp.episodeNumber}',
                                episodeNumber: firstEp.episodeNumber,
                                seasonNumber: state.selectedSeason,
                                posterUrl: detail.posterUrl,
                                downloadUrl: '',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bölüm indirme kuyruğuna eklendi'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download_for_offline_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceElevated,
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Genres Chips ────────────────────────────────────
                if (detail.genres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: detail.genres.map((genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _dynamicAccentColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _dynamicAccentColor.withAlpha(85),
                                width: 0.9,
                              ),
                            ),
                            child: Text(
                              genre,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),

                // ── Expandable Synopsis ─────────────────────────────
                if (detail.synopsis.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Özet', style: AppTypography.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSynopsisExpanded = !_isSynopsisExpanded;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  detail.synopsis,
                                  style: AppTypography.bodyMedium,
                                  maxLines: _isSynopsisExpanded ? null : 3,
                                  overflow: _isSynopsisExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isSynopsisExpanded
                                      ? 'Daha Az Göster'
                                      : 'Devamını Oku',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),

                // ── Cast Carousel ───────────────────────────────────
                if (state.cast.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: CastCarousel(cast: state.cast),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],

                // ── Episodes Header ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Text(
                      'Bölümler',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

                // ── Episode List Widget ─────────────────────────────
                SliverToBoxAdapter(
                  child: EpisodeListWidget(
                    animeId: detail.id,
                    seasons: detail.seasons,
                    episodes: state.episodes,
                    selectedSeason: state.selectedSeason,
                    onSeasonChanged: (season) {
                      context.read<AnimeDetailBloc>().add(
                            SeasonChangedEvent(
                              animeId: detail.id,
                              seasonNumber: season,
                            ),
                          );
                    },
                    onEpisodeTap: (episode) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => EpisodeDetailSheet(
                          animeDetail: detail,
                          episode: episode,
                          seasonNumber: state.selectedSeason,
                        ),
                      );
                    },
                    onDirectPlay: (episode) {
                      context.push(
                        '/watch/${detail.id}?url=&title=${Uri.encodeComponent(detail.title)}&episode=${Uri.encodeComponent(episode.title ?? 'Bölüm ${episode.episodeNumber}')}&ep=${episode.episodeNumber}&s=${state.selectedSeason}&poster=${Uri.encodeComponent(detail.posterUrl)}&episodeId=${Uri.encodeComponent(episode.id)}',
                      );
                    },
                  ),
                ),


                // ── Similar Anime Rail ──────────────────────────────
                if (state.similarAnime.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          child: Text(
                            'Benzer Animeler',
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: state.similarAnime.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final anime = state.similarAnime[index];
                              return AnimePosterCard(
                                id: anime.id,
                                title: anime.title,
                                posterUrl: anime.posterUrl,
                                fallbackUrls: [
                                  if (anime.bannerUrl != null &&
                                      anime.bannerUrl!.isNotEmpty)
                                    anime.bannerUrl!,
                                ],
                                rating: anime.rating,
                                onTap: () => context.push('/anime/${anime.id}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    ),
  );
}
}
