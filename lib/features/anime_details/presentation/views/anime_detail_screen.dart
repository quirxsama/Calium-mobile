import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/core/widgets/app_status_view.dart';
import 'package:calium_stream/core/widgets/section_header.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_cast_usecase.dart';
import 'package:calium_stream/features/anime_details/presentation/bloc/anime_detail_bloc.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/cast_carousel.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/episode_detail_sheet.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/episode_list_widget.dart';
import 'package:calium_stream/features/downloads/presentation/widgets/download_options_sheet.dart';
import 'package:calium_stream/features/home/presentation/widgets/anime_rail.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/user_lists/presentation/widgets/add_to_list_bottom_sheet.dart';

class AnimeDetailScreen extends StatelessWidget {
  const AnimeDetailScreen({required this.animeId, super.key});
  final String animeId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AnimeDetailBloc(
      getAnimeDetailUseCase: GetIt.I<GetAnimeDetailUseCase>(),
      getCastUseCase: GetIt.I<GetCastUseCase>(),
      repository: GetIt.I<AnimeDetailRepository>(),
    )..add(LoadAnimeDetailRequested(animeId: animeId)),
    child: _AnimeDetailView(animeId: animeId),
  );
}

class _AnimeDetailView extends StatefulWidget {
  const _AnimeDetailView({required this.animeId});
  final String animeId;
  @override
  State<_AnimeDetailView> createState() => _AnimeDetailViewState();
}

class _AnimeDetailViewState extends State<_AnimeDetailView> {
  bool _expandedSynopsis = false;

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Geri',
        onPressed: _back,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text('Anime detayları'),
    ),
    body: SafeArea(
      top: false,
      child: AppContentFrame(
        child: BlocBuilder<AnimeDetailBloc, AnimeDetailState>(
          builder: (context, state) {
            if (state is AnimeDetailFailureState) {
              return AppStatusView(
                title: 'Anime yüklenemedi',
                message: state.message,
                icon: Icons.error_outline_rounded,
                actions: [
                  FilledButton(
                    onPressed: () => context.read<AnimeDetailBloc>().add(
                      LoadAnimeDetailRequested(animeId: widget.animeId),
                    ),
                    child: const Text('Yeniden dene'),
                  ),
                ],
              );
            }
            if (state is! AnimeDetailLoaded) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Anime yükleniyor',
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final detail = state.detail;
                final overview = _overview(state);
                final episodes = _episodes(state);
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _DetailHeader(detail: detail, wide: wide),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 320, child: overview),
                                  const SizedBox(width: 32),
                                  Expanded(child: episodes),
                                ],
                              )
                            : Column(
                                children: [
                                  overview,
                                  const SizedBox(height: 32),
                                  episodes,
                                ],
                              ),
                      ),
                    ),
                    if (state.similarAnime.isNotEmpty)
                      SliverToBoxAdapter(
                        child: AnimeRail(
                          title: 'Benzer animeler',
                          animes: state.similarAnime,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                );
              },
            );
          },
        ),
      ),
    ),
  );

  Widget _overview(AnimeDetailLoaded state) {
    final detail = state.detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder(
          valueListenable: Hive.box('history').listenable(),
          builder: (context, Box box, _) {
            final saved = box.get(detail.id);
            var season = state.selectedSeason;
            var episode = state.episodes.isNotEmpty
                ? state.episodes.first.episodeNumber
                : 1;
            var title = state.episodes.isNotEmpty
                ? state.episodes.first.title ?? 'Bölüm $episode'
                : 'Bölüm $episode';
            var episodeId = state.episodes.isNotEmpty
                ? state.episodes.first.id
                : '';
            var resume = false;
            if (saved is Map) {
              final savedEpisode = int.tryParse(
                saved['episodeNumber']?.toString() ?? '',
              );
              if (savedEpisode != null && savedEpisode > 0) {
                resume = true;
                season =
                    int.tryParse(saved['seasonNumber']?.toString() ?? '') ??
                    season;
                episode = savedEpisode;
                title = saved['episodeName']?.toString() ?? 'Bölüm $episode';
                episodeId = saved['episodeId']?.toString() ?? '';
              }
            }
            if (episodeId.contains('_')) episodeId = '';
            return FilledButton.icon(
              onPressed: () => context.push(
                '/watch/${detail.id}?title=${Uri.encodeComponent(detail.title)}&episode=${Uri.encodeComponent(title)}&s=$season&ep=$episode&poster=${Uri.encodeComponent(detail.posterUrl)}&episodeId=${Uri.encodeComponent(episodeId)}',
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                resume ? 'Devam et · Bölüm $episode' : 'İzlemeye başla',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box('favorites').listenable(),
                builder: (context, Box box, _) {
                  final isFav = box.containsKey(detail.id);
                  return IconButton.outlined(
                    tooltip: isFav ? 'Favorilerden çıkar' : 'Favorilere ekle',
                    onPressed: () {
                      context.read<LibraryBloc>().add(
                        ToggleFavoriteRequested(
                          favorite: FavoriteEntity(
                            animeId: detail.id,
                            name: detail.title,
                            posterUrl: detail.posterUrl,
                            addedAt: DateTime.now(),
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? AppColors.accentCrimson
                          : AppColors.textPrimary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IconButton.outlined(
                tooltip: 'Listeye ekle',
                icon: const Icon(Icons.playlist_add_rounded),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddToListBottomSheet(
                    animeId: detail.id,
                    animeName: detail.title,
                    poster: detail.posterUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IconButton.outlined(
                tooltip: 'Bölümü indir',
                icon: const Icon(Icons.download_rounded),
                onPressed: state.episodes.isEmpty
                    ? null
                    : () {
                        final episode = state.episodes.first;
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DownloadOptionsSheet(
                            animeId: detail.id,
                            animeTitle: detail.title,
                            episodeTitle:
                                episode.title ??
                                'Bölüm ${episode.episodeNumber}',
                            episodeNumber: episode.episodeNumber,
                            seasonNumber: state.selectedSeason,
                            posterUrl: detail.posterUrl,
                            allSeasonEpisodes: state.episodes,
                          ),
                        );
                      },
              ),
            ),
          ],
        ),
        if (detail.genres.isNotEmpty) ...[
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final genre in detail.genres)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    genre,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (detail.synopsis.isNotEmpty) ...[
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'Hikâye',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail.synopsis,
            style: AppTypography.bodyMedium,
            maxLines: _expandedSynopsis ? null : 5,
            overflow: _expandedSynopsis ? null : TextOverflow.ellipsis,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  setState(() => _expandedSynopsis = !_expandedSynopsis),
              child: Text(
                _expandedSynopsis ? 'Daha az göster' : 'Devamını oku',
              ),
            ),
          ),
        ],
        if (state.cast.isNotEmpty) ...[
          const SizedBox(height: 24),
          CastCarousel(cast: state.cast),
        ],
      ],
    );
  }

  Widget _episodes(AnimeDetailLoaded state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Bölümler'),
      const SizedBox(height: 16),
      EpisodeListWidget(
        animeId: state.detail.id,
        animeTitle: state.detail.title,
        posterUrl: state.detail.posterUrl,
        seasons: state.detail.seasons,
        episodes: state.episodes,
        selectedSeason: state.selectedSeason,
        onSeasonChanged: (season) => context.read<AnimeDetailBloc>().add(
          SeasonChangedEvent(animeId: state.detail.id, seasonNumber: season),
        ),
        onEpisodeTap: (episode) => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => EpisodeDetailSheet(
            animeDetail: state.detail,
            episode: episode,
            seasonNumber: state.selectedSeason,
          ),
        ),
        onDirectPlay: (episode) => context.push(
          '/watch/${state.detail.id}?title=${Uri.encodeComponent(state.detail.title)}&episode=${Uri.encodeComponent(episode.title ?? 'Bölüm ${episode.episodeNumber}')}&ep=${episode.episodeNumber}&s=${state.selectedSeason}&poster=${Uri.encodeComponent(state.detail.posterUrl)}&episodeId=${Uri.encodeComponent(episode.id)}',
        ),
      ),
    ],
  );
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.detail, required this.wide});
  final AnimeDetailEntity detail;
  final bool wide;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: AppCachedImage(
          imageUrl: detail.bannerUrl ?? detail.posterUrl,
          fit: BoxFit.cover,
        ),
      ),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.background],
              stops: [0, 1],
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(24, wide ? 100 : 120, 24, 24),
        child: SizedBox(
          width: wide ? 820 : double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppCachedImage(
                imageUrl: detail.posterUrl,
                width: wide ? 160 : 88,
                height: wide ? 228 : 126,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
              ),
              SizedBox(width: wide ? 32 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        detail.title,
                        style: AppTypography.headlineLarge.copyWith(
                          fontSize: wide ? 38 : 24,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (detail.originalTitle?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        detail.originalTitle!,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (detail.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppColors.ratingAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                detail.rating!.toStringAsFixed(1),
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.ratingAmber,
                                ),
                              ),
                            ],
                          ),
                        if (detail.year != null)
                          Text(
                            '${detail.year}',
                            style: AppTypography.bodySmall,
                          ),
                        if (detail.status != null)
                          Text(detail.status!, style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
