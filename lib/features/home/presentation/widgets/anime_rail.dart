import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/section_header.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class AnimeRail extends StatelessWidget {
  const AnimeRail({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: SectionHeader(
            title: title,
            onSeeAll: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            scrollDirection: Axis.horizontal,
            cacheExtent: 500,
            addRepaintBoundaries: true,
            itemCount: animes.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final anime = animes[index];
              return AnimePosterCard(
                id: anime.id,
                title: anime.title,
                posterUrl: anime.posterUrl,
                rating: anime.rating,
                episodeBadge: anime.currentEpisode,
                width: AppSpacing.posterWidth,
                onTap: () => context.go('/anime/${anime.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}
