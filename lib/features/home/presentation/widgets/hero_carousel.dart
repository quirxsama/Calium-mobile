import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    required this.animes,
    super.key,
  });

  final List<AnimeEntity> animes;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.animes.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.animes.length.clamp(0, 5),
          options: CarouselOptions(
            height: 320,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 6),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final anime = widget.animes[index];
            final imageUrl = (anime.bannerUrl != null && anime.bannerUrl!.isNotEmpty)
                ? anime.bannerUrl!
                : anime.posterUrl;

            return GestureDetector(
              onTap: () => context.go('/anime/${anime.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    AppCachedImage(
                      imageUrl: imageUrl,
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
                            AppColors.background.withAlpha(120),
                            AppColors.background.withAlpha(240),
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Content Overlay
                    Positioned(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badges Row
                          Row(
                            children: [
                              if (anime.rating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 3,
                                  ),
                                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark.withAlpha(220),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.borderRadiusSm,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: AppColors.ratingAmber,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        anime.rating!.toStringAsFixed(1),
                                        style: AppTypography.badgeSmall,
                                      ),
                                    ],
                                  ),
                                ),

                              // Trending Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusSm,
                                  ),
                                ),
                                child: Text(
                                  'ÖNE ÇIKAN',
                                  style: AppTypography.badgeSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Title
                          Text(
                            anime.title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Genres
                          if (anime.genres.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              anime.genres.take(3).join(' • '),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
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
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.animes.length.clamp(0, 5),
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
