import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/navigation_utils.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/adaptive_poster_grid.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/explore/domain/repositories/explore_repository.dart';

class TrDubCatalogScreen extends StatefulWidget {
  const TrDubCatalogScreen({super.key});

  @override
  State<TrDubCatalogScreen> createState() => _TrDubCatalogScreenState();
}

class _TrDubCatalogScreenState extends State<TrDubCatalogScreen> {
  List<AnimeEntity> _animes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrDub();
  }

  Future<void> _fetchTrDub() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await GetIt.I<ExploreRepository>().getCatalog(
      kind: 'genre',
      genreId: ApiConstants.genreIds['Turkce_Dublaj']?.toString() ?? '66407',
    );

    res.fold(
      (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
      (list) => setState(() {
        _animes = list;
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => goBackOrHome(context),
        ),
        title: Text(
          'Türkçe Dublaj Animeler',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.accentCrimson,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchTrDub,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _animes.isEmpty
          ? const Center(
              child: Text(
                'Türkçe dublajlı anime bulunamadı.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          : AppContentFrame(
              child: AdaptivePosterGrid(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: _animes.length,
                itemBuilder: (context, index) {
                  final anime = _animes[index];
                  return AnimePosterCard(
                    id: anime.id,
                    title: anime.title,
                    posterUrl: anime.posterUrl,
                    rating: anime.rating ?? 0.0,
                    episodeBadge:
                        (anime.currentEpisode != null &&
                            anime.currentEpisode!.isNotEmpty)
                        ? anime.currentEpisode
                        : null,
                    onTap: () => context.push('/anime/${anime.id}'),
                  );
                },
              ),
            ),
    );
  }
}
