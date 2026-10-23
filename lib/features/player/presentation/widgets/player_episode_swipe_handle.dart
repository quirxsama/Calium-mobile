import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class PlayerEpisodeSwipeHandle extends StatefulWidget {
  const PlayerEpisodeSwipeHandle({
    required this.onOpen,
    this.isLocked = false,
    super.key,
  });

  final VoidCallback onOpen;
  final bool isLocked;

  @override
  State<PlayerEpisodeSwipeHandle> createState() =>
      _PlayerEpisodeSwipeHandleState();
}

class _PlayerEpisodeSwipeHandleState extends State<PlayerEpisodeSwipeHandle> {
  double _startY = 0;
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bölümleri göster',
      hint: 'Yukarı kaydırın veya dokunun',
      enabled: !widget.isLocked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (details) {
          _startY = details.localPosition.dy;
          _opened = false;
        },
        onVerticalDragUpdate: (details) {
          if (!widget.isLocked &&
              !_opened &&
              _startY - details.localPosition.dy >= 32) {
            _opened = true;
            widget.onOpen();
          }
        },
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: widget.isLocked
              ? const SizedBox.shrink()
              : Center(
                  child: TextButton.icon(
                    onPressed: widget.onOpen,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 24),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 16),
                    label: const Text(
                      'Bölümler',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
