import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({required this.animes, super.key});
  final List<AnimeEntity> animes;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.animes.take(6).length) {
      _index = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final count = widget.animes.take(6).length;
    if (count == 0) return;
    final page = (_index + delta) % count;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animes = widget.animes.take(6).toList();
    if (animes.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final extraTextHeight =
            (MediaQuery.textScalerOf(context).scale(28) - 28).clamp(0.0, 84.0);
        return Column(
          children: [
            SizedBox(
              height: (wide ? 480 : 420) + extraTextHeight * (wide ? 6 : 3),
              child: PageView.builder(
                controller: _controller,
                itemCount: animes.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 8),
                  child: _FeatureCard(anime: animes[index], wide: wide),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label:
                          'Öne çıkan anime ${_index + 1}, toplam ${animes.length}',
                      child: Row(
                        children: [
                          for (var i = 0; i < animes.length; i++)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              height: 4,
                              width: _index == i ? 28 : 8,
                              decoration: BoxDecoration(
                                color: _index == i
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Önceki anime',
                    onPressed: animes.length > 1 ? () => _move(-1) : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    tooltip: 'Sonraki anime',
                    onPressed: animes.length > 1 ? () => _move(1) : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.anime, required this.wide});
  final AnimeEntity anime;
  final bool wide;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Stack(
      fit: StackFit.expand,
      children: [
        AppCachedImage(
          imageUrl: anime.bannerUrl?.isNotEmpty == true
              ? anime.bannerUrl
              : anime.posterUrl,
          fallbackUrls: [anime.posterUrl],
          fit: BoxFit.cover,
          maxWidthDiskCache: 2560,
          maxHeightDiskCache: 1440,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: wide ? Alignment.centerLeft : Alignment.topCenter,
              end: wide ? Alignment.centerRight : Alignment.bottomCenter,
              colors: wide
                  ? [
                      AppColors.background.withAlpha(250),
                      AppColors.background.withAlpha(190),
                      AppColors.background.withAlpha(20),
                    ]
                  : [
                      AppColors.background.withAlpha(5),
                      AppColors.background.withAlpha(120),
                      AppColors.background.withAlpha(245),
                    ],
              stops: wide ? const [0, 0.45, 1] : const [0, 0.35, 1],
            ),
          ),
        ),
        Align(
          alignment: wide ? Alignment.centerLeft : Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(wide ? 36 : 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (anime.rating != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.ratingAmber,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          anime.rating!.toStringAsFixed(1),
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (anime.logoUrl != null && anime.logoUrl!.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: wide ? 360 : 260,
                        maxHeight: wide ? 84 : 64,
                      ),
                      child: AppCachedImage(
                        imageUrl: anime.logoUrl,
                        fit: BoxFit.contain,
                        maxWidthDiskCache: 1200,
                        errorWidget: Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineLarge.copyWith(
                            fontSize: wide ? 38 : 28,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                            letterSpacing: -0.7,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                  else
                    Semantics(
                      header: true,
                      child: Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: wide ? 38 : 28,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          letterSpacing: -0.7,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  if (anime.genres.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      anime.genres.take(3).join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (wide && anime.synopsis?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    Text(
                      anime.synopsis!.replaceAll(RegExp(r'<[^>]+>'), ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/anime/${anime.id}'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: const Text('Detayları gör'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
