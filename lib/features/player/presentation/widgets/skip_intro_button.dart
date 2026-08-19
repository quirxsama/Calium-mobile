import 'package:flutter/material.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

class SkipIntroButton extends StatelessWidget {
  const SkipIntroButton({
    required this.onPressed,
    this.isVisible = true,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      offset: isVisible ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isVisible ? 1.0 : 0.0,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
            ),
            elevation: 4,
          ),
          onPressed: isVisible ? onPressed : null,
          icon: const Icon(Icons.fast_forward_rounded, size: 18),
          label: Text(
            'İNTROYU GEÇ',
            style: AppTypography.badgeSmall.copyWith(
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
