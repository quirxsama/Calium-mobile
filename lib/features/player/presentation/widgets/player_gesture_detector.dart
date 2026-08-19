import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/utils/duration_formatter.dart';

enum ActiveGestureType { none, brightness, volume, horizontalScrub, longPressSpeed }

class PlayerGestureDetector extends StatefulWidget {
  const PlayerGestureDetector({
    required this.child,
    required this.currentPosition,
    required this.totalDuration,
    required this.isLocked,
    required this.onTap,
    required this.onDoubleTapLeft,
    required this.onDoubleTapRight,
    required this.onDoubleTapCenter,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onBrightnessChanged,
    required this.onVolumeChanged,
    required this.onSeek,
    this.initialBrightness = 1.0,
    this.initialVolume = 100.0,
    super.key,
  });

  final Widget child;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isLocked;
  final VoidCallback onTap;
  final ValueChanged<int> onDoubleTapLeft;
  final ValueChanged<int> onDoubleTapRight;
  final VoidCallback onDoubleTapCenter;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<Duration> onSeek;
  final double initialBrightness;
  final double initialVolume;

  @override
  State<PlayerGestureDetector> createState() => _PlayerGestureDetectorState();
}

class _PlayerGestureDetectorState extends State<PlayerGestureDetector> {
  // Ripple feedback
  bool _showLeftRipple = false;
  bool _showRightRipple = false;
  int _leftSeekSeconds = 0;
  int _rightSeekSeconds = 0;
  Timer? _leftRippleTimer;
  Timer? _rightRippleTimer;

  // Active gesture tracking
  ActiveGestureType _activeGesture = ActiveGestureType.none;
  double _brightness = 1.0;
  double _volume = 100.0;
  Duration _scrubTargetPosition = Duration.zero;
  Duration _scrubStartPosition = Duration.zero;
  Duration _scrubDelta = Duration.zero;

  // Tap position tracking
  Offset _lastDoubleTapPosition = Offset.zero;
  Offset _lastTapDownPosition = Offset.zero;

  // Drag start coordinators
  Offset _dragStartOffset = Offset.zero;
  bool _isDragging = false;
  Timer? _dismissOverlayTimer;

  @override
  void initState() {
    super.initState();
    _brightness = widget.initialBrightness;
    _volume = widget.initialVolume;
  }

  @override
  void didUpdateWidget(covariant PlayerGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBrightness != widget.initialBrightness) {
      _brightness = widget.initialBrightness;
    }
    if (oldWidget.initialVolume != widget.initialVolume) {
      _volume = widget.initialVolume;
    }
  }

  int _consecutiveLeftTaps = 0;
  int _consecutiveRightTaps = 0;
  DateTime? _lastLeftTapTime;
  DateTime? _lastRightTapTime;
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _leftRippleTimer?.cancel();
    _rightRippleTimer?.cancel();
    _singleTapTimer?.cancel();
    _dismissOverlayTimer?.cancel();
    super.dispose();
  }

  void _triggerLeftDoubleTap() {
    if (widget.isLocked) return;
    HapticFeedback.mediumImpact();
    _leftRippleTimer?.cancel();
    setState(() {
      _showLeftRipple = true;
      _leftSeekSeconds += 10;
    });
    // Seek 10s delta per tap step
    widget.onDoubleTapLeft(10);
    _leftRippleTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _showLeftRipple = false;
          _leftSeekSeconds = 0;
          _consecutiveLeftTaps = 0;
          _lastLeftTapTime = null;
        });
      }
    });
  }

  void _triggerRightDoubleTap() {
    if (widget.isLocked) return;
    HapticFeedback.mediumImpact();
    _rightRippleTimer?.cancel();
    setState(() {
      _showRightRipple = true;
      _rightSeekSeconds += 10;
    });
    // Seek 10s delta per tap step
    widget.onDoubleTapRight(10);
    _rightRippleTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _showRightRipple = false;
          _rightSeekSeconds = 0;
          _consecutiveRightTaps = 0;
          _lastRightTapTime = null;
        });
      }
    });
  }

  bool _skipNextTap = false;

  void _handleTapDown(TapDownDetails details, double screenWidth) {
    _lastTapDownPosition = details.localPosition;
    _skipNextTap = false;
    
    if (widget.isLocked) return;
    final now = DateTime.now();

    // Check Left Zone (< 38% width)
    if (_lastTapDownPosition.dx < screenWidth * 0.38) {
      if (_showLeftRipple || (_lastLeftTapTime != null && now.difference(_lastLeftTapTime!).inMilliseconds < 450)) {
        _singleTapTimer?.cancel();
        _singleTapTimer = null;
        _consecutiveLeftTaps++;
        _triggerLeftDoubleTap();
        _lastLeftTapTime = now;
        _skipNextTap = true;
        return;
      } else {
        _consecutiveLeftTaps = 1;
        _lastLeftTapTime = now;
      }
    } else {
      _consecutiveLeftTaps = 0;
      _lastLeftTapTime = null;
    }

    // Check Right Zone (> 62% width)
    if (_lastTapDownPosition.dx > screenWidth * 0.62) {
      if (_showRightRipple || (_lastRightTapTime != null && now.difference(_lastRightTapTime!).inMilliseconds < 450)) {
        _singleTapTimer?.cancel();
        _singleTapTimer = null;
        _consecutiveRightTaps++;
        _triggerRightDoubleTap();
        _lastRightTapTime = now;
        _skipNextTap = true;
        return;
      } else {
        _consecutiveRightTaps = 1;
        _lastRightTapTime = now;
      }
    } else {
      _consecutiveRightTaps = 0;
      _lastRightTapTime = null;
    }
  }

  void _handleSingleTap(double screenWidth) {
    if (widget.isLocked) {
      widget.onTap();
      return;
    }
    if (_skipNextTap || _showLeftRipple || _showRightRipple) {
      _skipNextTap = false;
      return;
    }

    final isSideZone = _lastTapDownPosition.dx < screenWidth * 0.38 || _lastTapDownPosition.dx > screenWidth * 0.62;
    if (isSideZone) {
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted && !_showLeftRipple && !_showRightRipple) {
          widget.onTap();
        }
      });
    } else {
      widget.onTap();
    }
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (widget.isLocked) return;
    _dragStartOffset = details.localPosition;
    _isDragging = false;
    _activeGesture = ActiveGestureType.none;
    _scrubStartPosition = widget.currentPosition;
    _dismissOverlayTimer?.cancel();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (widget.isLocked) return;

    final dx = details.localPosition.dx - _dragStartOffset.dx;
    final dy = details.localPosition.dy - _dragStartOffset.dy;

    // Detect gesture direction if not locked into one
    if (!_isDragging) {
      if (dx.abs() > 20 && dx.abs() > dy.abs()) {
        _isDragging = true;
        _activeGesture = ActiveGestureType.horizontalScrub;
      } else if (dy.abs() > 20) {
        _isDragging = true;
        final isLeft = _dragStartOffset.dx < (constraints.maxWidth / 2);
        _activeGesture = isLeft ? ActiveGestureType.brightness : ActiveGestureType.volume;
      }
    }

    if (!_isDragging) return;

    if (_activeGesture == ActiveGestureType.brightness) {
      final delta = -details.delta.dy / (constraints.maxHeight * 0.75);
      final newBrightness = (_brightness + delta).clamp(0.05, 1.0);
      setState(() => _brightness = newBrightness);
      widget.onBrightnessChanged(newBrightness);
    } else if (_activeGesture == ActiveGestureType.volume) {
      final delta = (-details.delta.dy / (constraints.maxHeight * 0.75)) * 100;
      final newVolume = (_volume + delta).clamp(0.0, 100.0);
      setState(() => _volume = newVolume);
      widget.onVolumeChanged(newVolume);
    } else if (_activeGesture == ActiveGestureType.horizontalScrub) {
      final scrubSeconds = (dx * 0.35).round();
      final totalMs = widget.totalDuration.inMilliseconds;
      if (totalMs > 0) {
        final newMs = (_scrubStartPosition.inMilliseconds + (scrubSeconds * 1000)).clamp(0, totalMs);
        final target = Duration(milliseconds: newMs);
        setState(() {
          _scrubTargetPosition = target;
          _scrubDelta = Duration(seconds: scrubSeconds);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isLocked) return;

    if (_activeGesture == ActiveGestureType.horizontalScrub) {
      widget.onSeek(_scrubTargetPosition);
    }

    _isDragging = false;
    _dismissOverlayTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _activeGesture = ActiveGestureType.none);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,

            // Single Unified Master Gesture Detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) => _handleTapDown(details, screenWidth),
                onTap: () => _handleSingleTap(screenWidth),
                onDoubleTapDown: (details) {
                  _lastDoubleTapPosition = details.localPosition;
                  _lastTapDownPosition = details.localPosition;
                },
                onDoubleTap: () {
                  if (widget.isLocked) return;
                  final x = _lastDoubleTapPosition.dx;
                  if (x >= screenWidth * 0.38 && x <= screenWidth * 0.62) {
                    widget.onDoubleTapCenter();
                  }
                },
                onLongPressStart: (_) {
                  if (!widget.isLocked) {
                    HapticFeedback.mediumImpact();
                    setState(() => _activeGesture = ActiveGestureType.longPressSpeed);
                    widget.onLongPressStart();
                  }
                },
                onLongPressEnd: (_) {
                  if (!widget.isLocked) {
                    setState(() => _activeGesture = ActiveGestureType.none);
                    widget.onLongPressEnd();
                  }
                },
                onLongPressCancel: () {
                  if (!widget.isLocked) {
                    setState(() => _activeGesture = ActiveGestureType.none);
                    widget.onLongPressEnd();
                  }
                },
                onPanStart: (d) => _onPanStart(d, constraints),
                onPanUpdate: (d) => _onPanUpdate(d, constraints),
                onPanEnd: _onPanEnd,
                child: Container(color: Colors.transparent),
              ),
            ),

            // ─── Double Tap Left Clean White Seek Ripple ──────────────────
            if (_showLeftRipple)
              _YouTubeSeekRippleOverlay(
                seconds: _leftSeekSeconds,
                isLeft: true,
              ),

            // ─── Double Tap Right Clean White Seek Ripple ─────────────────
            if (_showRightRipple)
              _YouTubeSeekRippleOverlay(
                seconds: _rightSeekSeconds,
                isLeft: false,
              ),

            // ─── Long Press 2x Speed Pill (Web Exact Copy) ────────────────
            if (_activeGesture == ActiveGestureType.longPressSpeed)
              const _TopCenter2xSpeedBadge(),

            // ─── Left Vertical Drag: Brightness Pill Overlay ─────────────────
            if (_activeGesture == ActiveGestureType.brightness)
              Positioned(
                left: 36,
                top: screenHeight * 0.25,
                bottom: screenHeight * 0.25,
                child: _buildVerticalSliderHUD(
                  icon: _brightness > 0.6
                      ? Icons.brightness_high_rounded
                      : (_brightness > 0.2 ? Icons.brightness_medium_rounded : Icons.brightness_low_rounded),
                  percentage: _brightness,
                  label: '${(_brightness * 100).round()}%',
                ),
              ),

            // ─── Right Vertical Drag: Volume Pill Overlay ────────────────────
            if (_activeGesture == ActiveGestureType.volume)
              Positioned(
                right: 36,
                top: screenHeight * 0.25,
                bottom: screenHeight * 0.25,
                child: _buildVerticalSliderHUD(
                  icon: _volume > 50
                      ? Icons.volume_up_rounded
                      : (_volume > 0 ? Icons.volume_down_rounded : Icons.volume_mute_rounded),
                  percentage: _volume / 100.0,
                  label: '${_volume.round()}%',
                ),
              ),

            // ─── Horizontal Scrub Center Bubble ──────────────────────────────
            if (_activeGesture == ActiveGestureType.horizontalScrub)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(220),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    border: Border.all(color: AppColors.primary.withAlpha(150)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _scrubDelta.inSeconds >= 0
                                ? Icons.fast_forward_rounded
                                : Icons.fast_rewind_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _scrubTargetPosition.toMinSecString(),
                            style: AppTypography.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            ' / ${widget.totalDuration.toMinSecString()}',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(${_scrubDelta.inSeconds >= 0 ? '+' : ''}${_scrubDelta.inSeconds} sn)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVerticalSliderHUD({
    required IconData icon,
    required double percentage,
    required String label,
  }) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(200),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(160),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(width: 6, color: Colors.white12),
                  FractionallySizedBox(
                    heightFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(150),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Exact Web Speed Boost Pill Copy
class _TopCenter2xSpeedBadge extends StatelessWidget {
  const _TopCenter2xSpeedBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '2x hız',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YouTubeSeekRippleOverlay extends StatefulWidget {
  const _YouTubeSeekRippleOverlay({
    required this.seconds,
    required this.isLeft,
  });

  final int seconds;
  final bool isLeft;

  @override
  State<_YouTubeSeekRippleOverlay> createState() => _YouTubeSeekRippleOverlayState();
}

class _YouTubeSeekRippleOverlayState extends State<_YouTubeSeekRippleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Positioned(
      left: widget.isLeft ? 0 : null,
      right: widget.isLeft ? null : 0,
      top: 0,
      bottom: 0,
      width: screenWidth * 0.35,
      child: ClipRRect(
        borderRadius: widget.isLeft
            ? const BorderRadius.horizontal(right: Radius.elliptical(160, 240))
            : const BorderRadius.horizontal(left: Radius.elliptical(160, 240)),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.75,
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final val = _animController.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final opacity = widget.isLeft
                            ? ((1.0 - val + (index * 0.33)) % 1.0).clamp(0.2, 1.0)
                            : ((val + (index * 0.33)) % 1.0).clamp(0.2, 1.0);
                        return Opacity(
                          opacity: opacity,
                          child: Icon(
                            widget.isLeft
                                ? Icons.arrow_left_rounded
                                : Icons.arrow_right_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.seconds} saniye',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
