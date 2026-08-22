import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';

class IntroSongBadge extends StatefulWidget {
  const IntroSongBadge({
    required this.song,
    required this.isVisible,
    this.isFadingOut = false,
    this.onDismissed,
    super.key,
  });

  final IntroSongEntity song;
  final bool isVisible;
  final bool isFadingOut;
  final VoidCallback? onDismissed;

  @override
  State<IntroSongBadge> createState() => _IntroSongBadgeState();
}

class _IntroSongBadgeState extends State<IntroSongBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isDismissedLocally = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openSpotify() async {
    if (widget.song.spotifyUrl.isEmpty) return;
    try {
      final uri = Uri.parse(widget.song.spotifyUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        final uri = Uri.parse(widget.song.spotifyUrl);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissedLocally) return const SizedBox.shrink();

    final show = widget.isVisible && !widget.isFadingOut;

    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0.0, 0.15),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !show,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(205),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  border: Border.all(
                    color: Colors.white.withAlpha(35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(140),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Cover Art / Music Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: Colors.white.withAlpha(20),
                        child: (widget.song.coverUrl != null &&
                                widget.song.coverUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: widget.song.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1DB954),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white60,
                                    size: 22,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white60,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 2. Song & Artist Meta Info (Tappable to open Spotify)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openSpotify,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FadeTransition(
                                  opacity: _pulseAnimation,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1DB954),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'İntro Şarkısı',
                                  style: TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.song.artist,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 3. Spotify Quick Action Button
                    GestureDetector(
                      onTap: _openSpotify,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954).withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF1DB954),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // 4. Close Button
                    GestureDetector(
                      onTap: () {
                        setState(() => _isDismissedLocally = true);
                        widget.onDismissed?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
