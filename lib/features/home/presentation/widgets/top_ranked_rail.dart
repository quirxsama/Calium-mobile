import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
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
    final posterWidth = MediaQuery.sizeOf(context).width >= 600 ? 164.0 : 140.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeader(title: title, onSeeAll: onSeeAll),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height:
              posterWidth / .7 +
              MediaQuery.textScalerOf(context).scale(14) * 2.6 +
              12,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: top10.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final anime = top10[index];
              return SizedBox(
                width: posterWidth + 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Semantics(
                        label: 'Sıra ${index + 1}',
                        child: Text(
                          '${index + 1}',
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(
                            fontSize: 32,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimePosterCard(
                        id: anime.id,
                        title: anime.title,
                        posterUrl: anime.posterUrl,
                        rating: anime.rating,
                        onTap: () => context.push('/anime/${anime.id}'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
