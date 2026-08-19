import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';

/// A dark-themed shimmer skeleton used as a loading placeholder.
///
/// Wraps the `shimmer` package with Calium's [AppColors.shimmerBase] and
/// [AppColors.shimmerHighlight] tokens so every skeleton in the app looks
/// consistent without repeating colour boilerplate.
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    this.width,
    this.height,
    this.borderRadius = AppSpacing.borderRadiusMd,
    super.key,
  });

  /// Width of the placeholder. Fills available space when `null`.
  final double? width;

  /// Height of the placeholder. Fills available space when `null`.
  final double? height;

  /// Corner radius of the rounded rectangle.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
