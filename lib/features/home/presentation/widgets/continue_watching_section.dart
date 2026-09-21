import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/section_header.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';

class ContinueWatchingSection extends StatelessWidget {
  const ContinueWatchingSection({this.items = const [], super.key});

  final List<AnimeEntity> items;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('history').listenable(),
      builder: (context, Box box, _) {
        // Collect watch history entries from Hive
        final List<Map<String, dynamic>> historyItems = [];
        for (final val in box.values) {
          if (val is Map) {
            historyItems.add(Map<String, dynamic>.from(val));
          }
        }

        // Most recently watched first
        historyItems.sort((a, b) {
          int toEpochMs(dynamic v) {
            if (v is num) return v.toInt();
            if (v is String) {
              return DateTime.tryParse(v)?.millisecondsSinceEpoch ?? 0;
            }
            return 0;
          }

          return toEpochMs(b['updatedAt']).compareTo(toEpochMs(a['updatedAt']));
        });

        if (historyItems.isEmpty && items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: SectionHeader(
                title: 'İzlemeye Devam Et',
                onSeeAll: () =>
                    _openContinueWatchingSheet(context, historyItems),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: historyItems.isNotEmpty
                    ? historyItems.length
                    : items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  if (historyItems.isNotEmpty) {
                    final item = historyItems[index];
                    final animeId = item['animeId']?.toString() ?? '';
                    final animeName = item['animeName']?.toString() ?? 'Anime';
                    final poster =
                        item['poster']?.toString() ??
                        item['posterUrl']?.toString() ??
                        '';
                    final episodeThumb = item['episodeThumb']?.toString() ?? '';
                    final rawProgress =
                        (item['progress'] as num?)?.toDouble() ?? 0.0;
                    final progress =
                        (rawProgress > 1.0 ? rawProgress / 100.0 : rawProgress)
                            .clamp(0.0, 1.0);
                    final epNum =
                        int.tryParse(item['episodeNumber']?.toString() ?? '') ??
                        1;
                    final sNum =
                        int.tryParse(item['seasonNumber']?.toString() ?? '') ??
                        1;
                    final episodeName = EpisodeUtils.formatEpisodeLabel(
                      season: sNum,
                      episode: epNum,
                      title: item['episodeName']?.toString(),
                    );

                    final rawEpId = item['episodeId']?.toString() ?? '';
                    final cleanEpId =
                        (rawEpId.isNotEmpty && !rawEpId.contains('_'))
                        ? rawEpId
                        : '';

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          '/watch/$animeId?title=${Uri.encodeComponent(animeName)}&episode=${Uri.encodeComponent(episodeName)}&ep=$epNum&s=$sNum&poster=${Uri.encodeComponent(poster)}&episodeId=${Uri.encodeComponent(cleanEpId)}',
                        );
                      },
                      onLongPress: () =>
                          _showRemoveDialog(context, animeId, animeName),
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail with Play Icon & Progress
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.borderRadiusMd,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Prefer the last watched episode thumbnail over the anime poster
                                    AppCachedImage(
                                      imageUrl: episodeThumb.isNotEmpty
                                          ? episodeThumb
                                          : poster,
                                      fallbackUrls: episodeThumb.isNotEmpty
                                          ? [poster]
                                          : const [],
                                      fit: BoxFit.cover,
                                    ),

                                    // Dark overlay with center play button
                                    Container(
                                      color: Colors.black38,
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: AppColors.primary,
                                          size: 44,
                                        ),
                                      ),
                                    ),

                                    // Progress bar at bottom
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: LinearProgressIndicator(
                                        value: progress.clamp(0.0, 1.0),
                                        backgroundColor: Colors.white24,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.primary,
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),

                            // Anime title
                            Text(
                              animeName,
                              style: AppTypography.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Episode label
                            Text(
                              episodeName,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Fallback to feed items
                  final item = items[index];
                  final progress = (item.watchProgress ?? 0.5).clamp(0.0, 1.0);

                  return GestureDetector(
                    onTap: () => context.go('/anime/${item.id}'),
                    child: SizedBox(
                      width: 220,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadiusMd,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppCachedImage(
                                    imageUrl: item.bannerUrl ?? item.posterUrl,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black26,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.title,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.currentEpisode != null)
                            Text(
                              item.currentEpisode!,
                              style: AppTypography.bodySmall,
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
      },
    );
  }

  void _openContinueWatchingSheet(
    BuildContext context,
    List<Map<String, dynamic>> historyItems,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContinueWatchingModal(
        historyItems: historyItems,
        onOpenHistory: () {
          Navigator.of(ctx).pop();
          context.go('/library?tab=history');
        },
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    String animeId,
    String animeName,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Geçmişten Kaldır',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '"$animeName" izleme geçmişinden kaldırılsın mı?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<LibraryBloc>().add(
                RemoveHistoryItemRequested(animeId: animeId),
              );
            },
            child: const Text(
              'Kaldır',
              style: TextStyle(
                color: AppColors.accentCrimson,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingModal extends StatelessWidget {
  const _ContinueWatchingModal({
    required this.historyItems,
    required this.onOpenHistory,
  });

  final List<Map<String, dynamic>> historyItems;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'İzlemeye Devam Et (${historyItems.length})',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpenHistory,
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Tüm Geçmiş'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: historyItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'İzleme geçmişi boş',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: historyItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final item = historyItems[idx];
                        final animeId = item['animeId']?.toString() ?? '';
                        final animeName =
                            item['animeName']?.toString() ?? 'Anime';
                        final poster =
                            item['poster']?.toString() ??
                            item['posterUrl']?.toString() ??
                            '';
                        final episodeThumb =
                            item['episodeThumb']?.toString() ?? '';
                        final rawProgress =
                            (item['progress'] as num?)?.toDouble() ?? 0.0;
                        final progress =
                            (rawProgress > 1.0
                                    ? rawProgress / 100.0
                                    : rawProgress)
                                .clamp(0.0, 1.0);
                        final epNum =
                            int.tryParse(
                              item['episodeNumber']?.toString() ?? '',
                            ) ??
                            1;
                        final sNum =
                            int.tryParse(
                              item['seasonNumber']?.toString() ?? '',
                            ) ??
                            1;
                        final episodeName = EpisodeUtils.formatEpisodeLabel(
                          season: sNum,
                          episode: epNum,
                          title: item['episodeName']?.toString(),
                        );
                        final rawEpId = item['episodeId']?.toString() ?? '';
                        final cleanEpId =
                            (rawEpId.isNotEmpty && !rawEpId.contains('_'))
                            ? rawEpId
                            : '';

                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 90,
                                  height: 56,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AppCachedImage(
                                        imageUrl: episodeThumb.isNotEmpty
                                            ? episodeThumb
                                            : poster,
                                        fallbackUrls: episodeThumb.isNotEmpty
                                            ? [poster]
                                            : const [],
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              const AlwaysStoppedAnimation(
                                                AppColors.primary,
                                              ),
                                          minHeight: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      animeName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      episodeName,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Kaldığın Yerden Oynat',
                                icon: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.push(
                                    '/watch/$animeId?title=${Uri.encodeComponent(animeName)}&episode=${Uri.encodeComponent(episodeName)}&ep=$epNum&s=$sNum&poster=${Uri.encodeComponent(poster)}&episodeId=${Uri.encodeComponent(cleanEpId)}',
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Geçmişten Kaldır',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  context.read<LibraryBloc>().add(
                                    RemoveHistoryItemRequested(
                                      animeId: animeId,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
