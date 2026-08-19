import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';

class DownloadOptionsSheet extends StatefulWidget {
  const DownloadOptionsSheet({
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.posterUrl,
    super.key,
  });

  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final int episodeNumber;
  final int seasonNumber;
  final String posterUrl;

  @override
  State<DownloadOptionsSheet> createState() => _DownloadOptionsSheetState();
}

class _DownloadOptionsSheetState extends State<DownloadOptionsSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  EpisodeSourceEntity? _sourceData;
  AudioGroupEntity? _selectedAudioGroup;
  VideoStreamItemEntity? _selectedStream;

  @override
  void initState() {
    super.initState();
    _fetchSources();
  }

  Future<void> _fetchSources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCase = GetIt.I<GetVideoSourcesUseCase>();
      final result = await useCase.call(
        GetVideoSourcesParams(
          animeId: widget.animeId,
          season: widget.seasonNumber,
          episode: widget.episodeNumber,
        ),
      );

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = failure.message;
            });
          }
        },
        (sourceData) {
          if (mounted) {
            AudioGroupEntity? initialGroup;
            VideoStreamItemEntity? initialStream;

            if (sourceData.audioGroups.isNotEmpty) {
              initialGroup = sourceData.audioGroups.first;
              if (initialGroup.streams.isNotEmpty) {
                initialStream = initialGroup.streams.first;
              }
            }

            setState(() {
              _isLoading = false;
              _sourceData = sourceData;
              _selectedAudioGroup = initialGroup;
              _selectedStream = initialStream;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kaynaklar yüklenemedi: $e';
        });
      }
    }
  }

  void _handleStartDownload() {
    if (_selectedStream == null || _selectedAudioGroup == null) return;

    DownloadService.instance.addTask(
      animeId: widget.animeId,
      animeTitle: widget.animeTitle,
      episodeTitle: widget.episodeTitle,
      episodeNumber: widget.episodeNumber,
      seasonNumber: widget.seasonNumber,
      posterUrl: widget.posterUrl,
      downloadUrl: _selectedStream!.url,
      quality: _selectedStream!.quality,
      audioName: _selectedAudioGroup!.name,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'İndirme başlatıldı: ${_selectedAudioGroup!.name} • ${_selectedStream!.quality}',
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
            const SizedBox(height: AppSpacing.md),

            // Header title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.download_for_offline_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İndirme Seçenekleri',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.animeTitle} • ${widget.episodeTitle}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (_isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Kalite ve dublaj seçenekleri taranıyor...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.accentCrimson, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _fetchSources,
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ] else if (_sourceData != null && _sourceData!.audioGroups.isNotEmpty) ...[
              // 1. Audio / Dubbing Selection
              const Text(
                'Ses & Dublaj Seçeneği',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sourceData!.audioGroups.map((group) {
                  final isSelected = _selectedAudioGroup == group;
                  return ChoiceChip(
                    label: Text(group.name),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedAudioGroup = group;
                          if (group.streams.isNotEmpty) {
                            final sameQuality = group.streams.where(
                              (s) => s.quality == _selectedStream?.quality,
                            );
                            _selectedStream = sameQuality.isNotEmpty
                                ? sameQuality.first
                                : group.streams.first;
                          } else {
                            _selectedStream = null;
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Quality Selection
              if (_selectedAudioGroup != null && _selectedAudioGroup!.streams.isNotEmpty) ...[
                const Text(
                  'Çözünürlük / Kalite',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedAudioGroup!.streams.map((stream) {
                    final isSelected = _selectedStream == stream;
                    return ChoiceChip(
                      avatar: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                          : const Icon(Icons.hd_outlined, color: AppColors.textMuted, size: 16),
                      label: Text(stream.quality),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceElevated,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStream = stream);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // 3. Start Download Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _selectedStream != null ? _handleStartDownload : null,
                icon: const Icon(Icons.download_rounded, size: 22),
                label: Text(
                  _selectedStream != null
                      ? '${_selectedStream!.quality} Olarak İndir'
                      : 'İndir',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Bu bölüm için aktif indirme kaynağı bulunamadı.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
