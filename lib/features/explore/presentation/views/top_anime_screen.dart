import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/repositories/home_repository.dart';

class TopAnimeScreen extends StatefulWidget {
  const TopAnimeScreen({super.key});

  @override
  State<TopAnimeScreen> createState() => _TopAnimeScreenState();
}

class _TopAnimeScreenState extends State<TopAnimeScreen> {
  List<AnimeEntity> _topAnimes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTop();
  }

  Future<void> _fetchTop() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await GetIt.I<HomeRepository>().getTopAnime(page: 1);
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
      (list) => setState(() {
        _topAnimes = list;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Top 10 Sıralaması',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.accentCrimson, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTypography.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTop,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  scrollCacheExtent: ScrollCacheExtent.pixels(500),
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: _topAnimes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final anime = _topAnimes[index];
                    final rank = index + 1;

                    Color rankColor = AppColors.textSecondary;
                    if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
                    if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
                    if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

                    return GestureDetector(
                      onTap: () => context.push('/anime/${anime.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            // Rank Number
                            Container(
                              width: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  color: rankColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: rank <= 3 ? 18 : 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Poster
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                              child: SizedBox(
                                width: 60,
                                height: 85,
                                child: AppCachedImage(
                                  imageUrl: anime.posterUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anime.title,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.ratingAmber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        anime.rating?.toStringAsFixed(1) ?? '0.0',
                                        style: const TextStyle(
                                          color: AppColors.ratingAmber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (anime.currentEpisode != null && anime.currentEpisode!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text('• ${anime.currentEpisode}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
