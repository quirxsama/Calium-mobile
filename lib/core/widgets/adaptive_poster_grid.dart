import 'package:flutter/material.dart';

class AdaptivePosterGrid extends StatelessWidget {
  const AdaptivePosterGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.physics,
    this.padding = const EdgeInsets.all(20),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsets padding;

  static SliverGridDelegateWithFixedCrossAxisCount delegateFor(
    BuildContext context,
    double width,
  ) {
    const gap = 16.0;
    final columns = ((width + gap) / (width >= 600 ? 180 : 140)).floor().clamp(
      2,
      8,
    );
    final tileWidth = (width - gap * (columns - 1)) / columns;
    final titleHeight = MediaQuery.textScalerOf(context).scale(14) * 2.6 + 12;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: tileWidth / .7 + titleHeight,
      crossAxisSpacing: gap,
      mainAxisSpacing: 24,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth - padding.horizontal;
      return GridView.builder(
        controller: controller,
        physics: physics,
        padding: padding,
        gridDelegate: delegateFor(context, width),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    },
  );
}
