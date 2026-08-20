import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';

String _formatSpeed(int bytesPerSec) {
  if (bytesPerSec > 1048576) return '${(bytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
  if (bytesPerSec > 1024) return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  return '$bytesPerSec B/s';
}

String _formatBytes(int bytes) {
  if (bytes > 1073741824) return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
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

  void _toggleExpand(String animeId) {
    setState(() {
      if (_expandedAnimeIds.contains(animeId)) {
        _expandedAnimeIds.remove(animeId);
      } else {
        _expandedAnimeIds.add(animeId);
      }
    });
  }

  void _confirmDeleteAnimeDownloads(String animeId, String animeTitle, List<DownloadTaskEntity> tasks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('$animeTitle İndirmelerini Sil', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Bu animeye ait ${tasks.length} bölümün indirilen dosyaları cihazınızdan tamamen silinecektir.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCrimson),
            onPressed: () {
              Navigator.pop(ctx);
              for (final t in tasks) {
                DownloadService.instance.removeTask(t.id);
              }
            },
            child: const Text('Tümünü Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
          'İndirilenler',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<DownloadTaskEntity>>(
        stream: DownloadService.instance.tasksStream,
        initialData: DownloadService.instance.currentTasks,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_for_offline_outlined, color: AppColors.textMuted, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Henüz indirilmiş bir bölüm yok',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'İnternetsiz olduğunuzda izlemek için anime detay sayfalarından bölümleri indirebilirsiniz.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group tasks by animeId
          final Map<String, List<DownloadTaskEntity>> grouped = {};
          for (final t in tasks) {
            grouped.putIfAbsent(t.animeId, () => []).add(t);
          }

          final animeIds = grouped.keys.toList();
          final totalUsedBytes = tasks.fold<int>(0, (sum, t) => sum + t.receivedBytes);

          return Column(
            children: [
              // Netflix Storage Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                color: AppColors.surfaceDark,
                child: Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Çevrimdışı Depolama',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Toplam ${tasks.length} bölüm • ${_formatBytes(totalUsedBytes)} kullanılıyor',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: animeIds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final animeId = animeIds[index];
                    final animeTasks = grouped[animeId]!;
                    final firstTask = animeTasks.first;
                    final isExpanded = _expandedAnimeIds.contains(animeId) || animeIds.length == 1;

                    final completedCount = animeTasks.where((t) => t.status == DownloadStatus.completed).length;
                    final animeTotalBytes = animeTasks.fold<int>(0, (sum, t) => sum + t.receivedBytes);

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          // Anime Header Tile
                          InkWell(
                            onTap: () => _toggleExpand(animeId),
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.cardPadding),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                                    child: SizedBox(
                                      width: 54,
                                      height: 76,
                                      child: firstTask.localPosterPath.isNotEmpty && File(firstTask.localPosterPath).existsSync()
                                          ? Image.file(File(firstTask.localPosterPath), fit: BoxFit.cover)
                                          : AppCachedImage(imageUrl: firstTask.posterUrl, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          firstTask.animeTitle,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${animeTasks.length} Bölüm ($completedCount Hazır) • ${_formatBytes(animeTotalBytes)}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.accentCrimson, size: 22),
                                    tooltip: 'Anime İndirmelerini Sil',
                                    onPressed: () => _confirmDeleteAnimeDownloads(animeId, firstTask.animeTitle, animeTasks),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Episodes Sub-list
                          if (isExpanded) ...[
                            const Divider(height: 1, color: AppColors.border),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              itemCount: animeTasks.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
                              itemBuilder: (ctx, epIndex) {
                                final task = animeTasks[epIndex];

                                String statusText;
                                Color statusColor;
                                switch (task.status) {
                                  case DownloadStatus.completed:
                                    statusText = 'Çevrimdışı İzlemeye Hazır';
                                    statusColor = AppColors.successGreen;
                                    break;
                                  case DownloadStatus.downloading:
                                    statusText = '%${(task.progress * 100).toInt()} indiriliyor... (${_formatSpeed(task.speedBytesPerSec)})';
                                    statusColor = AppColors.primary;
                                    break;
                                  case DownloadStatus.resolving:
                                    statusText = 'Bağlantı çözülüyor...';
                                    statusColor = Colors.orangeAccent;
                                    break;
                                  case DownloadStatus.failed:
                                    statusText = 'İndirme Başarısız';
                                    statusColor = AppColors.accentCrimson;
                                    break;
                                  case DownloadStatus.paused:
                                    statusText = 'Duraklatıldı';
                                    statusColor = AppColors.textMuted;
                                    break;
                                  default:
                                    statusText = 'Beklemede';
                                    statusColor = AppColors.primary;
                                }

                                final formattedEpName = EpisodeUtils.formatEpisodeLabel(
                                  season: task.seasonNumber,
                                  episode: task.episodeNumber,
                                  title: task.episodeTitle,
                                );

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Episode Play / Status Action Icon
                                          if (task.status == DownloadStatus.completed)
                                            IconButton(
                                              icon: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                                              ),
                                              onPressed: () {
                                                context.push(
                                                  '/watch/${task.animeId}?title=${Uri.encodeComponent(task.animeTitle)}&episode=${Uri.encodeComponent(task.episodeTitle)}&s=${task.seasonNumber}&ep=${task.episodeNumber}&poster=${Uri.encodeComponent(task.posterUrl)}',
                                                );
                                              },
                                            )
                                          else if (task.status == DownloadStatus.downloading)
                                            IconButton(
                                              icon: const Icon(Icons.pause_circle_filled_rounded, color: AppColors.primary, size: 32),
                                              onPressed: () => DownloadService.instance.pauseTask(task.id),
                                            )
                                          else if (task.status == DownloadStatus.paused)
                                            IconButton(
                                              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 32),
                                              onPressed: () => DownloadService.instance.resumeTask(task.id),
                                            )
                                          else if (task.status == DownloadStatus.failed)
                                            IconButton(
                                              icon: const Icon(Icons.refresh_rounded, color: AppColors.accentCrimson, size: 32),
                                              onPressed: () => DownloadService.instance.retryTask(task.id),
                                            )
                                          else
                                            const SizedBox(width: 48),

                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  formattedEpName,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    if (task.quality != null || task.audioName != null) ...[
                                                      Text(
                                                        '${task.quality ?? ''}${task.quality != null && task.audioName != null ? ' • ' : ''}${task.audioName ?? ''}',
                                                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                                      ),
                                                      const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                                    ],
                                                    Text(
                                                      _formatBytes(task.totalBytes > 0 ? task.totalBytes : task.receivedBytes),
                                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  statusText,
                                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),

                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
                                            onPressed: () => DownloadService.instance.removeTask(task.id),
                                          ),
                                        ],
                                      ),

                                      if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.paused) ...[
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: task.totalBytes > 0 ? (task.receivedBytes / task.totalBytes) : 0,
                                            backgroundColor: AppColors.surfaceElevated,
                                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
    );
  }
}
