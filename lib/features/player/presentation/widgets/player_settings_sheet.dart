import 'package:flutter/material.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';

class PlayerSettingsSheet extends StatefulWidget {
  const PlayerSettingsSheet({
    required this.audioGroups,
    required this.selectedAudioGroup,
    required this.selectedStream,
    required this.subtitles,
    this.selectedSubtitle,
    required this.playbackSpeed,
    required this.subtitleSize,
    required this.isFitCover,
    required this.autoSkipIntro,
    required this.autoNextEpisode,
    required this.onAudioGroupSelected,
    required this.onQualitySelected,
    required this.onSubtitleSelected,
    required this.onSpeedSelected,
    required this.onSubtitleSizeChanged,
    required this.onFitCoverToggled,
    required this.onAutoSkipIntroToggled,
    required this.onAutoNextEpisodeToggled,
    super.key,
  });

  final List<AudioGroupEntity> audioGroups;
  final AudioGroupEntity selectedAudioGroup;
  final VideoStreamItemEntity selectedStream;
  final List<SubtitleTrackEntity> subtitles;
  final SubtitleTrackEntity? selectedSubtitle;
  final double playbackSpeed;
  final int subtitleSize;
  final bool isFitCover;
  final bool autoSkipIntro;
  final bool autoNextEpisode;
  final ValueChanged<AudioGroupEntity> onAudioGroupSelected;
  final ValueChanged<VideoStreamItemEntity> onQualitySelected;
  final ValueChanged<SubtitleTrackEntity?> onSubtitleSelected;
  final ValueChanged<double> onSpeedSelected;
  final ValueChanged<int> onSubtitleSizeChanged;
  final VoidCallback onFitCoverToggled;
  final ValueChanged<bool> onAutoSkipIntroToggled;
  final ValueChanged<bool> onAutoNextEpisodeToggled;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const Map<String, int> _subtitleSizes = {
    'Küçük': 30,
    'Normal': 40,
    'Büyük': 52,
    'Çok Büyük': 64,
  };

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> {
  late bool _autoSkipIntro;
  late bool _autoNextEpisode;
  late bool _isFitCover;
  late AudioGroupEntity _selectedAudioGroup;
  late VideoStreamItemEntity _selectedStream;
  late SubtitleTrackEntity? _selectedSubtitle;
  late int _subtitleSize;
  late double _playbackSpeed;

  @override
  void initState() {
    super.initState();
    _autoSkipIntro = widget.autoSkipIntro;
    _autoNextEpisode = widget.autoNextEpisode;
    _isFitCover = widget.isFitCover;
    _selectedAudioGroup = widget.selectedAudioGroup;
    _selectedStream = widget.selectedStream;
    _selectedSubtitle = widget.selectedSubtitle;
    _subtitleSize = widget.subtitleSize;
    _playbackSpeed = widget.playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.borderRadiusXl),
        ),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Oynatıcı Ayarları',
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── 1. Ses / Dublaj ────────────────────────────────────
              if (widget.audioGroups.length > 1) ...[
                _buildSectionTitle('Ses / Dublaj Dili'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: widget.audioGroups.map((group) {
                    final isSelected = group == _selectedAudioGroup;
                    return _buildOptionChip(
                      label: group.name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedAudioGroup = group);
                        widget.onAudioGroupSelected(group);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const Divider(color: AppColors.border, height: 28),
              ],

              // ─── 2. Çözünürlük / Kalite ─────────────────────────────
              _buildSectionTitle('Çözünürlük / Kalite'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _selectedAudioGroup.streams.map((stream) {
                  final isSelected = stream.quality == _selectedStream.quality;
                  return _buildOptionChip(
                    label: stream.quality,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedStream = stream);
                      widget.onQualitySelected(stream);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(color: AppColors.border, height: 28),

              // ─── 3. Altyazı ─────────────────────────────────────────
              _buildSectionTitle('Altyazı Parçası'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildOptionChip(
                    label: 'Kapalı',
                    isSelected: _selectedSubtitle == null,
                    onTap: () {
                      setState(() => _selectedSubtitle = null);
                      widget.onSubtitleSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  ...widget.subtitles.map((sub) {
                    final isSelected = _selectedSubtitle == sub;
                    return _buildOptionChip(
                      label: sub.name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() => _selectedSubtitle = sub);
                        widget.onSubtitleSelected(sub);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
              const Divider(color: AppColors.border, height: 28),

              // ─── 4. Altyazı Boyutu ──────────────────────────────────
              _buildSectionTitle('Altyazı Boyutu'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: PlayerSettingsSheet._subtitleSizes.entries.map((
                  entry,
                ) {
                  final isSelected = _subtitleSize == entry.value;
                  return _buildOptionChip(
                    label: entry.key,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _subtitleSize = entry.value);
                      widget.onSubtitleSizeChanged(entry.value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(color: AppColors.border, height: 28),

              // ─── 5. Oynatma Hızı ────────────────────────────────────
              _buildSectionTitle('Oynatma Hızı'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: PlayerSettingsSheet._speeds.map((speed) {
                  final isSelected = (_playbackSpeed - speed).abs() < 0.01;
                  return _buildOptionChip(
                    label: '${speed}x',
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _playbackSpeed = speed);
                      widget.onSpeedSelected(speed);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(color: AppColors.border, height: 28),

              // ─── 6. Akıllı Oynatma Seçenekleri ───────────────────────
              _buildSectionTitle('Otomatik Oynatma & Görünüm'),
              const SizedBox(height: AppSpacing.sm),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusMd,
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: const Text(
                        'İntroyu Otomatik Atla',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Açılış introsu algılandığında elle basmadan atlar',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      value: _autoSkipIntro,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _autoSkipIntro = val);
                        widget.onAutoSkipIntroToggled(val);
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: const Text(
                        'Otomatik Sonraki Bölüm',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Bölüm bittiğinde 5sn sayaçla sonraki bölüme geçer',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      value: _autoNextEpisode,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _autoNextEpisode = val);
                        widget.onAutoNextEpisodeToggled(val);
                      },
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: const Text(
                        'Ekranı Doldur (Kırp / Zoom)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _isFitCover
                            ? 'Açık: Video siyah kenarlık olmadan tüm ekranı kaplar'
                            : 'Kapalı: Orijinal en-boy oranı korunur',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      value: _isFitCover,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() => _isFitCover = val);
                        widget.onFitCoverToggled();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
