import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';

class EpisodeListWidget extends StatefulWidget {
  const EpisodeListWidget({
    required this.animeId,
    required this.seasons,
    required this.episodes,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onEpisodeTap,
    this.onDirectPlay,
    super.key,
  });

  final String animeId;
  final List<SeasonEntity> seasons;
  final List<EpisodeEntity> episodes;
  final int selectedSeason;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<EpisodeEntity> onEpisodeTap;
  final ValueChanged<EpisodeEntity>? onDirectPlay;


  @override
  State<EpisodeListWidget> createState() => _EpisodeListWidgetState();
}

class _EpisodeListWidgetState extends State<EpisodeListWidget> {
  bool _isReversed = false;
  String _searchQuery = '';
  int _visibleChunk = 25;

  @override
  Widget build(BuildContext context) {
    // 1. Filter by search query
    List<EpisodeEntity> filtered = widget.episodes.where((ep) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final numMatch = ep.episodeNumber.toString() == q || 'bölüm ${ep.episodeNumber}'.contains(q);
      final titleMatch = ep.title?.toLowerCase().contains(q) ?? false;
      return numMatch || titleMatch;
    }).toList();

    // 2. Sort (ascending vs descending)
    if (_isReversed) {
      filtered = filtered.reversed.toList();
    }

    // 3. Paginate / Chunk max 25 episodes
    final displayedEpisodes = filtered.take(_visibleChunk).toList();
    final hasMore = filtered.length > _visibleChunk;

    // Read watch history from Hive
    final historyBox = Hive.box('history');
    final historyData = historyBox.get(widget.animeId) as Map?;
    final lastWatchedSeason = historyData?['seasonNumber'] as int?;
    final lastWatchedEp = historyData?['episodeNumber'] as int?;
    final watchProgress = (historyData?['progress'] as num?)?.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Season Tabs ─────────────────────────────────────────────
        if (widget.seasons.length > 1) ...[
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: widget.seasons.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final season = widget.seasons[index];
                final isSelected = season.seasonNumber == widget.selectedSeason;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _visibleChunk = 25;
                      _searchQuery = '';
                    });
                    widget.onSeasonChanged(season.seasonNumber);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                    ),
                    child: Center(
                      child: Text(
                        season.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Control Bar: Search & Sort Toggle ───────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              // Episode Search Box
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodySmall.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bölüm ara (örn. 12 veya isim)...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Sort Toggle Button
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                  ),
                ),
                tooltip: _isReversed ? 'Sondan Başa (N → 1)' : 'Baştan Sona (1 → N)',
                icon: Icon(
                  _isReversed ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(() => _isReversed = !_isReversed),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Episodes List ───────────────────────────────────────────
        if (widget.episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                'Bu sezonda henüz bölüm bulunmuyor.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: Text(
                'Aramanızla eşleşen bölüm bulunamadı.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedEpisodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final episode = displayedEpisodes[index];
              final isCurrentPlaying = lastWatchedSeason == widget.selectedSeason &&
                  lastWatchedEp == episode.episodeNumber;

              final epProgress = isCurrentPlaying ? (watchProgress ?? 0.0) : (episode.watchProgress ?? 0.0);

              return GestureDetector(
                onTap: () => widget.onEpisodeTap(episode),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isCurrentPlaying
                        ? AppColors.primary.withAlpha(20)
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    border: Border.all(
                      color: isCurrentPlaying ? AppColors.primary : AppColors.border,
                      width: isCurrentPlaying ? 1.0 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail with direct play action
                      GestureDetector(
                        onTap: () {
                          if (widget.onDirectPlay != null) {
                            widget.onDirectPlay!(episode);
                          } else {
                            widget.onEpisodeTap(episode);
                          }
                        },
                        child: SizedBox(
                          width: 100,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppCachedImage(
                                  imageUrl: episode.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: AppColors.surfaceElevated,
                                    child: const Icon(
                                      Icons.play_circle_outline,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),

                                // Play Icon Overlay
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCurrentPlaying ? Icons.play_arrow_rounded : Icons.play_arrow_outlined,
                                      color: isCurrentPlaying ? AppColors.primary : Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),

                                // Progress bar
                                if (epProgress > 0.0)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: epProgress,
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      minHeight: 3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    EpisodeUtils.formatEpisodeLabel(
                                      season: widget.selectedSeason,
                                      episode: episode.episodeNumber,
                                      title: episode.title,
                                    ),
                                    style: AppTypography.titleSmall.copyWith(
                                      color: isCurrentPlaying ? AppColors.primary : AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isCurrentPlaying) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'KALINAN YER',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 9,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                                if (episode.isFiller) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'FILLER',
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 9,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (episode.overview != null && episode.overview!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  episode.overview!,
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (episode.duration != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${(episode.duration! / 60).round()} dk',
                                style: AppTypography.caption,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Watch Icon
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // ── Load More / Pagination Chunking Button ──────────────────
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _visibleChunk += 25;
                  });
                },
                icon: const Icon(Icons.expand_more_rounded, color: AppColors.primary),
                label: Text(
                  'Daha Fazla Bölüm Göster (${filtered.length - _visibleChunk} Kalan)',
                  style: AppTypography.titleSmall.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
