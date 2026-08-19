import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';

/// A frosted-glass container that applies a backdrop blur to its background.
///
/// Used throughout the Calium UI for overlays, bottom sheets, and floating
/// action panels – mirroring the glassmorphism aesthetic of the web project.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.borderRadius = AppSpacing.borderRadiusLg,
    this.blur = 12.0,
    this.padding,
    this.border,
    super.key,
  });

  /// The widget rendered inside the glass panel.
  final Widget child;

  /// Corner radius applied to the clip and decoration.
  final double borderRadius;

  /// Sigma value for the backdrop blur effect.
  final double blur;

  /// Optional inner padding. Defaults to `null` (no padding).
  final EdgeInsetsGeometry? padding;

  /// Optional border. When `null` a thin [AppColors.border] line is used.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(
                  color: AppColors.border,
                  width: 0.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
