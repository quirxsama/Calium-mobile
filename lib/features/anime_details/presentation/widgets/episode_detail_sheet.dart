import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/downloads/presentation/widgets/download_options_sheet.dart';

class EpisodeDetailSheet extends StatelessWidget {
  const EpisodeDetailSheet({
    required this.animeDetail,
    required this.episode,
    required this.seasonNumber,
    super.key,
  });

  final AnimeDetailEntity animeDetail;
  final EpisodeEntity episode;
  final int seasonNumber;

  void _startPlayback(BuildContext context) {
    Navigator.of(context).pop();
    final epTitle = episode.title ?? 'Bölüm ${episode.episodeNumber}';
    context.push(
      '/watch/${animeDetail.id}?url=&title=${Uri.encodeComponent(animeDetail.title)}&episode=${Uri.encodeComponent(epTitle)}&ep=${episode.episodeNumber}&s=$seasonNumber',
    );
  }

  void _downloadEpisode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DownloadOptionsSheet(
        animeId: animeDetail.id,
        animeTitle: animeDetail.title,
        episodeTitle: episode.title ?? 'Bölüm ${episode.episodeNumber}',
        episodeNumber: episode.episodeNumber,
        seasonNumber: seasonNumber,
        posterUrl: animeDetail.posterUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final epTitle = EpisodeUtils.formatEpisodeLabel(
      season: seasonNumber,
      episode: episode.episodeNumber,
      title: episode.title,
    );
    final hasThumbnail = episode.thumbnailUrl != null && episode.thumbnailUrl!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Thumbnail / Banner with overlay badge
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasThumbnail
                        ? AppCachedImage(
                            imageUrl: episode.thumbnailUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.surfaceElevated,
                            child: const Center(
                              child: Icon(Icons.movie_creation_outlined, size: 48, color: AppColors.textMuted),
                            ),
                          ),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Season & Episode Pill
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(190),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.5),
                      ),
                      child: Text(
                        EpisodeUtils.formatEpisodeLabel(
                          season: seasonNumber,
                          episode: episode.episodeNumber,
                        ),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  if (episode.isFiller)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(180),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'FILLER',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),

                  // Center Play Action
                  Positioned.fill(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _startPlayback(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(220),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(140),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 32),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Episode Title & Info
            Text(
              epTitle,
              style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  animeDetail.title,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (episode.duration != null) ...[
                  Text(' • ', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  Text(
                    '${(episode.duration! / 60).round()} dakika',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),

            if (episode.overview != null && episode.overview!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                episode.overview!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action Buttons Row
            Row(
              children: [
                // Watch Now Button (Main)
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _startPlayback(context),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'Şimdi İzle',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Download Button (Opens Quality & Audio Options)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _downloadEpisode(context),
                  icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                  label: const Text(
                    'İndir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
