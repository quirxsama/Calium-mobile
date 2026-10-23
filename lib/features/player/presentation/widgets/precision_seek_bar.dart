import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/utils/duration_formatter.dart';

Duration clampPlayerSeek(Duration position, Duration duration) => Duration(
  microseconds: position.inMicroseconds.clamp(
    0,
    duration.inMicroseconds > 0 ? duration.inMicroseconds : 0,
  ),
);

class PrecisionSeekBar extends StatefulWidget {
  const PrecisionSeekBar({
    required this.position,
    required this.duration,
    required this.onSeek,
    this.buffered = Duration.zero,
    this.enabled = true,
    this.onSeekStart,
    this.onSeekEnd,
    this.onPreviewSeek,
    super.key,
  });

  final Duration position;
  final Duration duration;
  final Duration buffered;
  final bool enabled;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration>? onPreviewSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;

  @override
  State<PrecisionSeekBar> createState() => _PrecisionSeekBarState();
}

class _PrecisionSeekBarState extends State<PrecisionSeekBar> {
  double? _previewMs;
  Offset _origin = Offset.zero;
  Offset _last = Offset.zero;
  bool _precise = false;
  DateTime _lastPreviewSeek = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _enabled => widget.enabled && widget.duration > Duration.zero;
  double get _max =>
      widget.duration.inMilliseconds.toDouble().clamp(0, double.infinity);
  Duration get _display => clampPlayerSeek(
    _previewMs == null
        ? widget.position
        : Duration(milliseconds: _previewMs!.round()),
    widget.duration,
  );

  void _notifyPreview(Duration target) {
    final now = DateTime.now();
    if (now.difference(_lastPreviewSeek).inMilliseconds >= 30) {
      _lastPreviewSeek = now;
      widget.onPreviewSeek?.call(target);
    }
  }

  void _finish({bool commit = false}) {
    if (_previewMs == null) return;
    final target = _display;
    setState(() {
      _previewMs = null;
      _precise = false;
    });
    if (commit && _enabled) {
      widget.onSeek(target);
    } else if (!commit && _enabled) {
      widget.onPreviewSeek?.call(widget.position);
    }
    widget.onSeekEnd?.call();
  }

  void _step(int seconds) {
    widget.onSeekStart?.call();
    widget.onSeek(
      clampPlayerSeek(
        widget.position + Duration(seconds: seconds),
        widget.duration,
      ),
    );
    widget.onSeekEnd?.call();
  }

  @override
  void didUpdateWidget(covariant PrecisionSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _previewMs != null) {
      _previewMs = null;
      _precise = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSeekEnd?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _display.toMinSecString();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 32).clamp(1.0, double.infinity);
        double positionAt(double x) =>
            ((x - 16) / width * _max).clamp(0.0, _max);
        return Semantics(
          label: 'Oynatma konumu',
          value: time,
          hint: 'Hassas sarma için yukarı sürükleyin',
          slider: true,
          enabled: _enabled,
          increasedValue: clampPlayerSeek(
            _display + const Duration(seconds: 5),
            widget.duration,
          ).toMinSecString(),
          decreasedValue: clampPlayerSeek(
            _display - const Duration(seconds: 5),
            widget.duration,
          ).toMinSecString(),
          onIncrease: _enabled ? () => _step(5) : null,
          onDecrease: _enabled ? () => _step(-5) : null,
          child: Listener(
            onPointerCancel: (_) => _finish(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: _enabled
                  ? (details) {
                      widget.onSeekStart?.call();
                      widget.onSeek(
                        Duration(
                          milliseconds: positionAt(details.localPosition.dx)
                              .round(),
                        ),
                      );
                      widget.onSeekEnd?.call();
                    }
                  : null,
              onPanStart: _enabled
                  ? (details) {
                      _origin = _last = details.localPosition;
                      setState(() => _previewMs = positionAt(_origin.dx));
                      widget.onSeekStart?.call();
                      _notifyPreview(_display);
                    }
                  : null,
              onPanUpdate: _enabled
                  ? (details) {
                      if (_previewMs == null) return;
                      setState(() {
                        _precise = _origin.dy - details.localPosition.dy >= 40;
                        final delta = details.localPosition.dx - _last.dx;
                        _previewMs =
                            (_previewMs! +
                                    delta / width * _max * (_precise ? 0.1 : 1))
                                .clamp(0.0, _max);
                        _last = details.localPosition;
                      });
                      _notifyPreview(_display);
                    }
                  : null,
              onPanEnd: (_) => _finish(commit: true),
              onPanCancel: _finish,
              child: SizedBox(
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(
                        value: _max == 0
                            ? 0
                            : clampPlayerSeek(
                                    widget.buffered,
                                    widget.duration,
                                  ).inMilliseconds /
                                  _max,
                        color: Colors.white38,
                        backgroundColor: Colors.white24,
                        minHeight: 4,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LinearProgressIndicator(
                        value: _max == 0
                            ? 0
                            : (_display.inMilliseconds / _max).clamp(0.0, 1.0),
                        color: AppColors.primary,
                        backgroundColor: Colors.transparent,
                        minHeight: _precise ? 6 : 4,
                      ),
                    ),
                    Positioned(
                      left:
                          8 +
                          (_max == 0 ? 0 : _display.inMilliseconds / _max) *
                              width,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 16, height: 16),
                      ),
                    ),
                    if (_previewMs != null)
                      Positioned(
                        bottom: 48,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark.withAlpha(240),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _precise
                                    ? AppColors.primary
                                    : Colors.white24,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _precise
                                        ? 'Hassas sarma'
                                        : 'Hassas sarma için yukarı sürükleyin',
                                    style: TextStyle(
                                      color: _precise
                                          ? AppColors.primary
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
