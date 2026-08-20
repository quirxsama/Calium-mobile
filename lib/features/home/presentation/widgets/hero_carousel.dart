import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

/// Web-style hero carousel: wide horizontal banner backgrounds with Ken Burns
/// zoom, anime logos (fallback to title text) and animated crossfade content.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    required this.animes,
    super.key,
  });

  final List<AnimeEntity> animes;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _kenBurnsController;

  @override
  void initState() {
    super.initState();
    _kenBurnsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _kenBurnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animes = widget.animes.take(6).toList();
    if (animes.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: animes.length,
          options: CarouselOptions(
            height: 230,
            viewportFraction: 0.94,
            enlargeCenterPage: true,
            enlargeFactor: 0.06,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 7),
            autoPlayAnimationDuration: const Duration(milliseconds: 900),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final anime = animes[index];
            return _HeroCard(
              anime: anime,
              isActive: index == _currentIndex,
              kenBurnsAnimation: _kenBurnsController,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),

        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            animes.length,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.anime,
    required this.isActive,
    required this.kenBurnsAnimation,
  });

  final AnimeEntity anime;
  final bool isActive;
  final Animation<double> kenBurnsAnimation;

  @override
  Widget build(BuildContext context) {
    // Prefer wide banner (landscape) over poster for the background
    final bannerUrl = (anime.bannerUrl != null && anime.bannerUrl!.isNotEmpty)
        ? anime.bannerUrl!
        : anime.posterUrl;

    return GestureDetector(
      onTap: () => context.go('/anime/${anime.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background: Ken Burns animated wide image ──────────
            AnimatedBuilder(
              animation: kenBurnsAnimation,
              builder: (context, child) {
                final scale = isActive
                    ? 1.0 + (kenBurnsAnimation.value * 0.08)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: AppCachedImage(
                imageUrl: bannerUrl,
                fallbackUrls: [anime.posterUrl],
                fit: BoxFit.cover,
              ),
            ),

            // ── Cinematic gradient scrims ──────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xAA0B0E14),
                    Color(0xF20B0E14),
                  ],
                  stops: [0.25, 0.65, 1.0],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x880B0E14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // ── Content overlay (crossfades on page change) ────────
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.md,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey(anime.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badges row
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
                              color: Colors.black.withValues(alpha: 0.45),
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
                    const SizedBox(height: AppSpacing.sm),

                    // ── Logo image (web-style) or bold title fallback ──
                    if (anime.logoUrl != null && anime.logoUrl!.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.55,
                          maxHeight: 52,
                        ),
                        child: AppCachedImage(
                          imageUrl: anime.logoUrl,
                          fit: BoxFit.contain,
                          errorWidget: _TitleFallback(title: anime.title),
                        ),
                      )
                    else
                      _TitleFallback(title: anime.title),

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
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleFallback extends StatelessWidget {
  const _TitleFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.headlineMedium.copyWith(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
        shadows: const [
          Shadow(color: Colors.black54, blurRadius: 8),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
