import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/section_header.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class TopRankedRail extends StatelessWidget {
  const TopRankedRail({
    required this.title,
    required this.animes,
    this.onSeeAll,
    super.key,
  });

  final String title;
  final List<AnimeEntity> animes;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (animes.isEmpty) return const SizedBox.shrink();

    final top10 = animes.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: SectionHeader(
            title: title,
            onSeeAll: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            scrollDirection: Axis.horizontal,
            cacheExtent: 600,
            itemCount: top10.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (context, index) {
              final anime = top10[index];
              final rank = index + 1;

              return GestureDetector(
                onTap: () => context.push('/anime/${anime.id}'),
                child: SizedBox(
                  width: 170,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Large Stylized Rank Number (Left & Behind)
                      Positioned(
                        left: -8,
                        bottom: -12,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -6,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = AppColors.primary.withAlpha(200),
                            shadows: [
                              Shadow(
                                color: AppColors.primary.withAlpha(90),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: -8,
                        bottom: -12,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 100,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -6,
                            color: AppColors.background.withAlpha(220),
                          ),
                        ),
                      ),

                      // Poster Card (Right side)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(160),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppCachedImage(
                                  imageUrl: anime.posterUrl,
                                  fit: BoxFit.cover,
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
                                          Colors.black.withAlpha(190),
                                        ],
                                        stops: const [0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // Rating Badge Top Right
                                if (anime.rating != null && anime.rating! > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.ratingAmber.withAlpha(100), width: 0.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: AppColors.ratingAmber, size: 11),
                                          const SizedBox(width: 2),
                                          Text(
                                            anime.rating!.toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: AppColors.ratingAmber,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Title at bottom
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: Text(
                                    anime.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
  }
}
