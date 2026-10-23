import 'package:flutter/material.dart';

import 'precision_seek_bar.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/duration_formatter.dart';

class PlayerControlsHUD extends StatefulWidget {
  const PlayerControlsHUD({
    required this.isPlaying,
    required this.position,
    this.positionListenable,
    required this.duration,
    required this.buffered,
    required this.animeTitle,
    required this.episodeTitle,
    required this.selectedQuality,
    required this.selectedAudioName,
    this.selectedSubtitleName,
    required this.playbackSpeed,
    required this.isFitCover,
    required this.isLocked,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onSeek,
    this.onPreviewSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.onBack,
    required this.onOpenAudioModal,
    required this.onOpenQualityModal,
    required this.onOpenSubtitleModal,
    required this.onOpenSpeedModal,
    required this.onToggleAspectRatio,
    required this.onToggleLock,
    this.onBackgroundTap,
    this.onOpenEpisodesModal,
    this.onPreviousEpisode,
    this.onNextEpisode,
    super.key,
  });

  final bool isPlaying;
  final Duration position;
  final ValueNotifier<Duration>? positionListenable;
  final Duration duration;
  final Duration buffered;
  final String animeTitle;
  final String episodeTitle;
  final String selectedQuality;
  final String selectedAudioName;
  final String? selectedSubtitleName;
  final double playbackSpeed;
  final bool isFitCover;
  final bool isLocked;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration>? onPreviewSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final VoidCallback onBack;
  final VoidCallback onOpenAudioModal;
  final VoidCallback onOpenQualityModal;
  final VoidCallback onOpenSubtitleModal;
  final VoidCallback onOpenSpeedModal;
  final VoidCallback onToggleAspectRatio;
  final VoidCallback onToggleLock;
  final VoidCallback? onBackgroundTap;
  final VoidCallback? onOpenEpisodesModal;
  final VoidCallback? onPreviousEpisode;
  final VoidCallback? onNextEpisode;

  @override
  State<PlayerControlsHUD> createState() => _PlayerControlsHUDState();
}

class _PlayerControlsHUDState extends State<PlayerControlsHUD> {
  @override
  Widget build(BuildContext context) {
    final maxDurationMs = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds.toDouble()
        : 1.0;

    // When Screen is Locked: Render ONLY the floating Unlock button
    if (widget.isLocked) {
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onBackgroundTap,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: 36,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: widget.onToggleLock,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(210),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(120),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onBackgroundTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withAlpha(230),
              Colors.transparent,
              Colors.black.withAlpha(240),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ─── Top Bar: Back, Titles, Quick Setting Badges & Lock ────────
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: AppSpacing.xs),

                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.animeTitle,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.episodeTitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Quick Setting Badges (Horizontally scrollable to prevent overflow)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Episodes Drawer Button
                          if (widget.onOpenEpisodesModal != null) ...[
                            _buildQuickBadge(
                              icon: Icons.view_list_rounded,
                              label: 'Bölümler',
                              onTap: widget.onOpenEpisodesModal!,
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Audio / Dub Selector Chip
                          _buildQuickBadge(
                            icon: Icons.record_voice_over_outlined,
                            label: widget.selectedAudioName,
                            onTap: widget.onOpenAudioModal,
                          ),
                          const SizedBox(width: 6),

                          // Quality Selector Chip
                          _buildQuickBadge(
                            icon: Icons.hd_outlined,
                            label: widget.selectedQuality,
                            onTap: widget.onOpenQualityModal,
                          ),
                          const SizedBox(width: 6),

                          // Subtitle Selector Chip
                          _buildQuickBadge(
                            icon: Icons.subtitles_outlined,
                            label: widget.selectedSubtitleName ?? 'Kapalı',
                            onTap: widget.onOpenSubtitleModal,
                          ),
                          const SizedBox(width: 6),

                          // Speed Selector Chip
                          _buildQuickBadge(
                            icon: Icons.speed_rounded,
                            label: '${widget.playbackSpeed}x',
                            onTap: widget.onOpenSpeedModal,
                          ),
                          const SizedBox(width: 6),

                          // Aspect Ratio Toggle
                          IconButton(
                            tooltip: widget.isFitCover
                                ? 'Ekrana Sığdır'
                                : 'Ekranı Doldur',
                            icon: Icon(
                              widget.isFitCover
                                  ? Icons.fit_screen_rounded
                                  : Icons.aspect_ratio_rounded,
                              color: widget.isFitCover
                                  ? AppColors.primary
                                  : Colors.white,
                              size: 20,
                            ),
                            onPressed: widget.onToggleAspectRatio,
                          ),

                          // Lock Screen Button
                          IconButton(
                            tooltip: 'Ekranı Kilitle',
                            icon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: widget.onToggleLock,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Center Controls: Perfectly Balanced 5-Button Cluster ───
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Previous Episode
                  _buildCircularControlButton(
                    icon: Icons.skip_previous_rounded,
                    size: 46,
                    iconSize: 26,
                    tooltip: 'Önceki Bölüm',
                    isEnabled: widget.onPreviousEpisode != null,
                    onPressed: widget.onPreviousEpisode ?? () {},
                  ),
                  const SizedBox(width: 24),

                  // 2. Rewind 10s
                  _buildCircularControlButton(
                    icon: Icons.replay_10_rounded,
                    size: 52,
                    iconSize: 30,
                    tooltip: '10 Saniye Geri',
                    isEnabled: true,
                    onPressed: widget.onSeekBackward,
                  ),
                  const SizedBox(width: 28),

                  // 3. Center Play/Pause with Soft Glow
                  GestureDetector(
                    onTap: widget.onPlayPause,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(150),
                            blurRadius: 24,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey<bool>(widget.isPlaying),
                            color: Colors.black,
                            size: 42,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),

                  // 4. Forward 10s
                  _buildCircularControlButton(
                    icon: Icons.forward_10_rounded,
                    size: 52,
                    iconSize: 30,
                    tooltip: '10 Saniye İleri',
                    isEnabled: true,
                    onPressed: widget.onSeekForward,
                  ),
                  const SizedBox(width: 24),

                  // 5. Next Episode
                  _buildCircularControlButton(
                    icon: Icons.skip_next_rounded,
                    size: 46,
                    iconSize: 26,
                    tooltip: 'Sonraki Bölüm',
                    isEnabled: widget.onNextEpisode != null,
                    onPressed: widget.onNextEpisode ?? () {},
                  ),
                ],
              ),
            ),

            // ─── Bottom Timeline, Sliders & Time Counter ───────────────
            SafeArea(
              top: false,
              child: widget.positionListenable != null
                  ? ValueListenableBuilder<Duration>(
                      valueListenable: widget.positionListenable!,
                      builder: (context, currentPos, _) {
                        return _buildTimelineRow(
                          context,
                          currentPos,
                          maxDurationMs,
                        );
                      },
                    )
                  : _buildTimelineRow(context, widget.position, maxDurationMs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    Duration currentPos,
    double maxDurationMs,
  ) {
    final displayTimeStr = clampPlayerSeek(
      currentPos,
      widget.duration,
    ).toMinSecString();

    return Row(
      children: [
        Text(
          displayTimeStr,
          style: AppTypography.badgeSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PrecisionSeekBar(
            position: currentPos,
            duration: widget.duration,
            buffered: widget.buffered,
            enabled: !widget.isLocked,
            onSeek: widget.onSeek,
            onPreviewSeek: widget.onPreviewSeek,
            onSeekStart: widget.onSeekStart,
            onSeekEnd: widget.onSeekEnd,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          widget.duration.toMinSecString(),
          style: AppTypography.badgeSmall.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularControlButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onPressed,
    bool isEnabled = true,
    String? tooltip,
  }) {
    final button = GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.35,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isEnabled ? 28 : 12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(isEnabled ? 35 : 15),
              width: 1,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );

    if (tooltip != null && isEnabled) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  Widget _buildQuickBadge({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          border: Border.all(color: Colors.white.withAlpha(35), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
