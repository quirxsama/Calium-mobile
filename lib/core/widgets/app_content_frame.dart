import 'package:flutter/material.dart';

/// Keeps large windows useful without stretching reading surfaces edge to edge.
class AppContentFrame extends StatelessWidget {
  const AppContentFrame({super.key, required this.child, this.maxWidth = 1400});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
