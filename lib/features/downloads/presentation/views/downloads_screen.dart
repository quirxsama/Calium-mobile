import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/utils/navigation_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';

String _formatSpeed(int bytesPerSec) {
  if (bytesPerSec > 1048576) {
    return '${(bytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
  }
  if (bytesPerSec > 1024) {
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }
  return '$bytesPerSec B/s';
}

String _formatBytes(int bytes) {
  if (bytes > 1073741824) {
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
  if (bytes > 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final Set<String> _expandedAnimeIds = {};
  final Map<String, int> _selectedSeasonPerAnime = {};

  void _toggleExpand(String animeId) {
    setState(() {
      if (_expandedAnimeIds.contains(animeId)) {
        _expandedAnimeIds.remove(animeId);
      } else {
        _expandedAnimeIds.add(animeId);
      }
    });
  }

  void _confirmDeleteAnimeDownloads(
    String animeId,
    String animeTitle,
    List<DownloadTaskEntity> tasks,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentCrimson.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.accentCrimson,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Anime İndirmelerini Sil',
                style: AppTypography.headlineMedium.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          '$animeTitle animesine ait ${tasks.length} bölümün indirilen tüm video ve altyazı dosyaları cihazınızdan tamamen silinecektir.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCrimson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DownloadService.instance.removeAnimeTasks(animeId);
            },
            child: const Text(
              'Tümünü Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSeasonDownloads(
    String animeId,
    String animeTitle,
    int seasonNumber,
    List<DownloadTaskEntity> tasks,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentCrimson.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.accentCrimson,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$seasonNumber. Sezonu Sil',
                style: AppTypography.headlineMedium.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          '$animeTitle $seasonNumber. Sezonuna ait ${tasks.length} bölüm cihazınızdan silinecektir.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCrimson,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              DownloadService.instance.removeSeasonTasks(animeId, seasonNumber);
            },
            child: const Text(
              'Sezonu Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppContentFrame(
      maxWidth: 1040,
      child: PopScope(
        canPop: canGoBack(context),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) goBackOrHome(context);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Geri',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => goBackOrHome(context),
            ),
            title: Text(
              'İndirilenler',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: StreamBuilder<List<DownloadTaskEntity>>(
              stream: DownloadService.instance.tasksStream,
              initialData: DownloadService.instance.currentTasks,
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceElevated,
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(80),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(40),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.download_for_offline_rounded,
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Çevrimdışı İzlemek İçin İndirin',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'İnternet bağlantınız olmadığında veya seyahat ederken anime bölümlerini yüksek kalitede çevrimdışı izleyebilirsiniz.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.go('/'),
                              icon: const Icon(Icons.explore_rounded, size: 20),
                              label: const Text(
                                'Anime Keşfet',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Group tasks by animeId
                final Map<String, List<DownloadTaskEntity>> grouped = {};
                for (final t in tasks) {
                  grouped.putIfAbsent(t.animeId, () => []).add(t);
                }

                final animeIds = grouped.keys.toList();
                final totalUsedBytes = tasks.fold<int>(
                  0,
                  (sum, t) => sum + t.receivedBytes,
                );
                final readyCount = tasks
                    .where((t) => t.status == DownloadStatus.completed)
                    .length;
                final activeCount = tasks
                    .where(
                      (t) =>
                          t.status == DownloadStatus.downloading ||
                          t.status == DownloadStatus.resolving,
                    )
                    .length;
                final failedCount = tasks
                    .where((t) => t.status == DownloadStatus.failed)
                    .length;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          0,
                          AppSpacing.screenPadding,
                          AppSpacing.md,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusLg,
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.storage_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Çevrimdışı Depolama',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '$readyCount hazır • $activeCount indiriliyor${failedCount > 0 ? ' • $failedCount başarısız' : ''}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatBytes(totalUsedBytes)} video verisi alındı',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Anime Downloads Group List ─────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: animeIds.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final animeId = animeIds[index];
                          final animeTasks = grouped[animeId]!;
                          final firstTask = animeTasks.first;
                          final isExpanded =
                              _expandedAnimeIds.contains(animeId) ||
                              animeIds.length == 1;

                          final completedCount = animeTasks
                              .where(
                                (t) => t.status == DownloadStatus.completed,
                              )
                              .length;
                          final animeTotalBytes = animeTasks.fold<int>(
                            0,
                            (sum, t) => sum + t.receivedBytes,
                          );

                          // Group anime tasks by Season Number
                          final Map<int, List<DownloadTaskEntity>>
                          seasonGroups = {};
                          for (final t in animeTasks) {
                            seasonGroups
                                .putIfAbsent(t.seasonNumber, () => [])
                                .add(t);
                          }
                          final seasons = seasonGroups.keys.toList()..sort();
                          final savedSeason = _selectedSeasonPerAnime[animeId];
                          final selectedSeason = seasons.contains(savedSeason)
                              ? savedSeason!
                              : seasons.first;
                          final currentSeasonTasks =
                              seasonGroups[selectedSeason] ?? animeTasks;
                          currentSeasonTasks.sort(
                            (a, b) =>
                                a.episodeNumber.compareTo(b.episodeNumber),
                          );

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadiusLg,
                              ),
                              border: Border.all(
                                color: isExpanded
                                    ? AppColors.primary.withAlpha(120)
                                    : AppColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Anime Header Tile
                                InkWell(
                                  onTap: () => _toggleExpand(animeId),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.borderRadiusLg,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.cardPadding,
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.borderRadiusSm,
                                          ),
                                          child: SizedBox(
                                            width: 54,
                                            height: 76,
                                            child:
                                                firstTask
                                                        .localPosterPath
                                                        .isNotEmpty &&
                                                    File(
                                                      firstTask.localPosterPath,
                                                    ).existsSync()
                                                ? Image.file(
                                                    File(
                                                      firstTask.localPosterPath,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : AppCachedImage(
                                                    imageUrl:
                                                        firstTask.posterUrl,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                firstTask.animeTitle,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${animeTasks.length} Bölüm ($completedCount Hazır) • ${_formatBytes(animeTotalBytes)}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (seasons.length > 1) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${seasons.length} sezon',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_sweep_rounded,
                                            color: AppColors.accentCrimson,
                                            size: 22,
                                          ),
                                          tooltip: 'Tüm İndirmeleri Sil',
                                          onPressed: () =>
                                              _confirmDeleteAnimeDownloads(
                                                animeId,
                                                firstTask.animeTitle,
                                                animeTasks,
                                              ),
                                        ),
                                        Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up_rounded
                                              : Icons
                                                    .keyboard_arrow_down_rounded,
                                          color: AppColors.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Expanded Season Breakdown & Episode List
                                if (isExpanded) ...[
                                  const Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),

                                  // Season Pills (if multiple seasons downloaded)
                                  if (seasons.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: seasons.map((sNum) {
                                                  final isSelected =
                                                      sNum == selectedSeason;
                                                  final count =
                                                      seasonGroups[sNum]
                                                          ?.length ??
                                                      0;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 8.0,
                                                        ),
                                                    child: ChoiceChip(
                                                      label: Text(
                                                        '$sNum. Sezon ($count)',
                                                      ),
                                                      selected: isSelected,
                                                      selectedColor:
                                                          AppColors.primary,
                                                      backgroundColor: AppColors
                                                          .surfaceElevated,
                                                      labelStyle: TextStyle(
                                                        color: isSelected
                                                            ? Colors.black
                                                            : Colors.white,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.w500,
                                                        fontSize: 12,
                                                      ),
                                                      onSelected: (selected) {
                                                        if (selected) {
                                                          setState(() {
                                                            _selectedSeasonPerAnime[animeId] =
                                                                sNum;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.textMuted,
                                            ),
                                            tooltip:
                                                '$selectedSeason. Sezon İndirmelerini Sil',
                                            onPressed: () =>
                                                _confirmDeleteSeasonDownloads(
                                                  animeId,
                                                  firstTask.animeTitle,
                                                  selectedSeason,
                                                  currentSeasonTasks,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Episodes Sub-list
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    itemCount: currentSeasonTasks.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      color: Colors.white10,
                                    ),
                                    itemBuilder: (ctx, epIndex) {
                                      final task = currentSeasonTasks[epIndex];

                                      String statusText;
                                      Color statusColor;
                                      switch (task.status) {
                                        case DownloadStatus.completed:
                                          statusText =
                                              'Çevrimdışı İzlemeye Hazır';
                                          statusColor = AppColors.successGreen;
                                          break;
                                        case DownloadStatus.downloading:
                                          statusText =
                                              task.errorMessage.isNotEmpty
                                              ? task.errorMessage
                                              : '${task.progress > 0 ? '%${(task.progress * 100).toInt()} • ' : ''}${_formatBytes(task.receivedBytes)} alındı • ${_formatSpeed(task.speedBytesPerSec)}';
                                          statusColor = AppColors.primary;
                                          break;
                                        case DownloadStatus.resolving:
                                          statusText = 'İndirme hazırlanıyor…';
                                          statusColor = Colors.orangeAccent;
                                          break;
                                        case DownloadStatus.failed:
                                          statusText = task.errorMessage.isEmpty
                                              ? 'İndirme başarısız. Yeniden deneyin.'
                                              : task.errorMessage;
                                          statusColor = AppColors.textPrimary;
                                          break;
                                        case DownloadStatus.paused:
                                          statusText = task.errorMessage.isEmpty
                                              ? 'Duraklatıldı • Devam edebilirsiniz'
                                              : task.errorMessage;
                                          statusColor = AppColors.textSecondary;
                                          break;
                                        default:
                                          statusText = 'İndirme sırasında';
                                          statusColor = AppColors.primary;
                                      }

                                      final formattedEpName =
                                          EpisodeUtils.formatEpisodeLabel(
                                            season: task.seasonNumber,
                                            episode: task.episodeNumber,
                                            title: task.episodeTitle,
                                          );

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 6,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // 1. Play Button / Progress / Action
                                                if (task.status ==
                                                    DownloadStatus.completed)
                                                  IconButton(
                                                    tooltip: 'Çevrimdışı oynat',
                                                    icon: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: AppColors
                                                                .primary,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        Icons
                                                            .play_arrow_rounded,
                                                        color: Colors.black,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      context.push(
                                                        '/watch/${task.animeId}?title=${Uri.encodeComponent(task.animeTitle)}&episode=${Uri.encodeComponent(task.episodeTitle)}&s=${task.seasonNumber}&ep=${task.episodeNumber}&poster=${Uri.encodeComponent(task.posterUrl)}&url=${Uri.encodeComponent(task.savePath)}',
                                                      );
                                                    },
                                                  )
                                                else if (task.status ==
                                                        DownloadStatus
                                                            .downloading ||
                                                    task.status ==
                                                        DownloadStatus
                                                            .resolving ||
                                                    task.status ==
                                                        DownloadStatus.pending)
                                                  IconButton(
                                                    tooltip:
                                                        'İndirmeyi duraklat',
                                                    icon: const Icon(
                                                      Icons
                                                          .pause_circle_filled_rounded,
                                                      color: AppColors.primary,
                                                      size: 32,
                                                    ),
                                                    onPressed: () =>
                                                        DownloadService.instance
                                                            .pauseTask(task.id),
                                                  )
                                                else if (task.status ==
                                                    DownloadStatus.paused)
                                                  IconButton(
                                                    tooltip:
                                                        'İndirmeye devam et',
                                                    icon: const Icon(
                                                      Icons
                                                          .play_circle_fill_rounded,
                                                      color: AppColors.primary,
                                                      size: 32,
                                                    ),
                                                    onPressed: () =>
                                                        DownloadService.instance
                                                            .resumeTask(
                                                              task.id,
                                                            ),
                                                  )
                                                else if (task.status ==
                                                    DownloadStatus.failed)
                                                  IconButton(
                                                    tooltip: 'Yeniden dene',
                                                    icon: const Icon(
                                                      Icons.refresh_rounded,
                                                      color: AppColors
                                                          .accentCrimson,
                                                      size: 32,
                                                    ),
                                                    onPressed: () =>
                                                        DownloadService.instance
                                                            .retryTask(task.id),
                                                  )
                                                else
                                                  const SizedBox(width: 48),

                                                const SizedBox(width: 8),

                                                // 2. Episode Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        formattedEpName,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          if (task.quality !=
                                                                  null ||
                                                              task.audioName !=
                                                                  null) ...[
                                                            Text(
                                                              '${task.quality ?? ''}${task.quality != null && task.audioName != null ? ' • ' : ''}${task.audioName ?? ''}',
                                                              style: const TextStyle(
                                                                color: AppColors
                                                                    .primary,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            const Text(
                                                              ' • ',
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .textMuted,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ],
                                                          Text(
                                                            _formatBytes(
                                                              task.totalBytes >
                                                                      0
                                                                  ? task.totalBytes
                                                                  : task.receivedBytes,
                                                            ),
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          if (task
                                                              .localSubtitles
                                                              .isNotEmpty) ...[
                                                            const Text(
                                                              ' • ',
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .textMuted,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                            const Text(
                                                              'Altyazılı',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        statusText,
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // 3. Delete Episode Button
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: AppColors.textMuted,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'Bölümü Sil',
                                                  onPressed: () async {
                                                    final confirmed = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text(
                                                          'Bölüm silinsin mi?',
                                                        ),
                                                        content: Text(
                                                          '$formattedEpName için indirilen video ve altyazılar silinecek.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  false,
                                                                ),
                                                            child: const Text(
                                                              'Vazgeç',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  ctx,
                                                                  true,
                                                                ),
                                                            child: const Text(
                                                              'Sil',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirmed == true) {
                                                      DownloadService.instance
                                                          .removeTask(task.id);
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),

                                            // Download Progress Bar
                                            if (task.status ==
                                                    DownloadStatus
                                                        .downloading ||
                                                task.status ==
                                                    DownloadStatus.paused) ...[
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value:
                                                      task.progress > 0 ||
                                                          task.status ==
                                                              DownloadStatus
                                                                  .paused
                                                      ? task.progress.clamp(
                                                          0.0,
                                                          1.0,
                                                        )
                                                      : null,
                                                  semanticsLabel:
                                                      '$formattedEpName indirme ilerlemesi',
                                                  backgroundColor:
                                                      AppColors.surfaceElevated,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation(
                                                        AppColors.primary,
                                                      ),
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
