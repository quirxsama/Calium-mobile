import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/downloads/presentation/widgets/download_options_sheet.dart';

class EpisodeListWidget extends StatefulWidget {
  const EpisodeListWidget({
    required this.animeId,
    this.animeTitle = '',
    this.posterUrl = '',
    required this.seasons,
    required this.episodes,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onEpisodeTap,
    this.onDirectPlay,
    super.key,
  });
  final String animeId;
  final String animeTitle;
  final String posterUrl;
  final List<SeasonEntity> seasons;
  final List<EpisodeEntity> episodes;
  final int selectedSeason;
  final ValueChanged<int> onSeasonChanged;
  final ValueChanged<EpisodeEntity> onEpisodeTap;
  final ValueChanged<EpisodeEntity>? onDirectPlay;
  @override
  State<EpisodeListWidget> createState() => _EpisodeListWidgetState();
}

class _EpisodeListWidgetState extends State<EpisodeListWidget> {
  final _search = TextEditingController();
  bool _reversed = false;
  int _visible = 25;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    var filtered = widget.episodes
        .where(
          (episode) =>
              query.isEmpty ||
              episode.episodeNumber.toString() == query ||
              'bölüm ${episode.episodeNumber}'.contains(query) ||
              (episode.title?.toLowerCase().contains(query) ?? false),
        )
        .toList();
    if (_reversed) filtered = filtered.reversed.toList();
    final visible = filtered.take(_visible).toList();
    return ValueListenableBuilder(
      valueListenable: Hive.box('history').listenable(),
      builder: (context, Box box, _) {
        final rawHistory = box.get(widget.animeId);
        final history = rawHistory is Map ? rawHistory : const {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.seasons.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final season in widget.seasons)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(season.name),
                          selected:
                              season.seasonNumber == widget.selectedSeason,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: AppTypography.titleSmall.copyWith(
                            color: season.seasonNumber == widget.selectedSeason
                                ? AppColors.background
                                : AppColors.textPrimary,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _visible = 25;
                                _search.clear();
                              });
                              widget.onSeasonChanged(season.seasonNumber);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() => _visible = 25),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Bölüm ara',
                      prefixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: _reversed
                      ? 'İlk bölümden sırala'
                      : 'Son bölümden sırala',
                  onPressed: () => setState(() => _reversed = !_reversed),
                  icon: Icon(
                    _reversed
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                  ),
                ),
                if (widget.episodes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: '${widget.selectedSeason}. sezonu indir',
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DownloadOptionsSheet(
                        animeId: widget.animeId,
                        animeTitle: widget.animeTitle,
                        episodeTitle: '${widget.selectedSeason}. Sezon',
                        episodeNumber: widget.episodes.first.episodeNumber,
                        seasonNumber: widget.selectedSeason,
                        posterUrl: widget.posterUrl,
                        allSeasonEpisodes: widget.episodes,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  widget.episodes.isEmpty
                      ? 'Bu sezonda henüz bölüm bulunmuyor.'
                      : 'Aramanızla eşleşen bölüm bulunamadı.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final episode in visible) ...[
              _episodeTile(episode, history),
              const SizedBox(height: 12),
            ],
            if (filtered.length > _visible)
              OutlinedButton.icon(
                onPressed: () => setState(() => _visible += 25),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text('Daha fazla bölüm (${filtered.length - _visible})'),
              ),
          ],
        );
      },
    );
  }

  Widget _episodeTile(EpisodeEntity episode, Map history) {
    final current =
        history['seasonNumber'] == widget.selectedSeason &&
        history['episodeNumber'] == episode.episodeNumber;
    final rawProgress = current
        ? (history['progress'] as num?)?.toDouble() ?? 0
        : episode.watchProgress ?? 0;
    final progress = (rawProgress > 1 ? rawProgress / 100 : rawProgress).clamp(
      0.0,
      1.0,
    );
    final label = EpisodeUtils.formatEpisodeLabel(
      season: widget.selectedSeason,
      episode: episode.episodeNumber,
      title: episode.title,
    );
    return Material(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: current ? AppColors.primary : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onEpisodeTap(episode),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final thumbnailWidth = constraints.maxWidth >= 500
                  ? 144.0
                  : constraints.maxWidth < 300
                  ? 76.0
                  : 100.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    label: '$label oynat',
                    child: InkWell(
                      onTap: () =>
                          (widget.onDirectPlay ?? widget.onEpisodeTap)(episode),
                      child: SizedBox(
                        width: thumbnailWidth,
                        height: thumbnailWidth * .68,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppCachedImage(
                                imageUrl: episode.thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.textPrimary,
                                  size: 32,
                                ),
                              ),
                              if (progress > 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 3,
                                    semanticsLabel: 'İzleme ilerlemesi',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (current)
                              Text(
                                'Kaldığın yer',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            if (episode.duration != null)
                              Text(
                                '${(episode.duration! / 60).round()} dk',
                                style: AppTypography.caption,
                              ),
                            if (episode.isFiller)
                              Text('Filler', style: AppTypography.caption),
                          ],
                        ),
                        if (episode.overview?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            episode.overview!,
                            style: AppTypography.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
