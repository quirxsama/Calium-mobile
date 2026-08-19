import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/section_header.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({
    this.items = const [],
    super.key,
  });

  final List<AnimeEntity> items;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('history').listenable(),
      builder: (context, Box box, _) {
        // Collect watch history entries from Hive
        final List<Map<String, dynamic>> historyItems = [];
        for (var i = box.length - 1; i >= 0; i--) {
          final val = box.getAt(i);
          if (val is Map) {
            historyItems.add(Map<String, dynamic>.from(val));
          }
        }

        if (historyItems.isEmpty && items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: SectionHeader(
                title: 'İzlemeye Devam Et',
                onSeeAll: () => context.go('/library'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: historyItems.isNotEmpty ? historyItems.length : items.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (historyItems.isNotEmpty) {
                    final item = historyItems[index];
                    final animeId = item['animeId']?.toString() ?? '';
                    final animeName = item['animeName']?.toString() ?? 'Anime';
                    final poster = item['poster']?.toString() ?? item['posterUrl']?.toString() ?? '';
                    final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
                    final epNum = int.tryParse(item['episodeNumber']?.toString() ?? '') ?? 1;
                    final sNum = int.tryParse(item['seasonNumber']?.toString() ?? '') ?? 1;
                    final episodeName = EpisodeUtils.formatEpisodeLabel(
                      season: sNum,
                      episode: epNum,
                      title: item['episodeName']?.toString(),
                    );

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          '/watch/$animeId?title=${Uri.encodeComponent(animeName)}&episode=${Uri.encodeComponent(episodeName)}&ep=$epNum&s=$sNum',
                        );
                      },
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail with Play Icon & Progress
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadiusMd,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppCachedImage(
                                      imageUrl: poster,
                                      fit: BoxFit.cover,
                                    ),

                                    // Dark overlay with center play button
                                    Container(
                                      color: Colors.black38,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: AppColors.primary,
                                          size: 44,
                                        ),
                                      ),
                                    ),

                                    // Progress bar at bottom
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Anime title
                            Text(
                              animeName,
                              style: AppTypography.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Episode label
                            Text(
                              episodeName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Fallback to feed items
                  final item = items[index];
                  final progress = (item.watchProgress ?? 0.5).clamp(0.0, 1.0);

                  return GestureDetector(
                    onTap: () => context.go('/anime/${item.id}'),
                    child: SizedBox(
                      width: 220,
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
                                  AppCachedImage(
                                    imageUrl: item.bannerUrl ?? item.posterUrl,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black26,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.title,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.currentEpisode != null)
                            Text(
                              item.currentEpisode!,
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
