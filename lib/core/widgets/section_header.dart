import 'package:flutter/material.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

/// A row containing a section [title] and an optional *Tümünü Gör* action.
///
/// Used at the top of horizontal list sections on the Home, Discover, and
/// similar screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.onSeeAll,
    super.key,
  });

  /// Section title displayed on the left.
  final String title;

  /// When non-null a "Tümünü Gör" text button is rendered on the right.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: AppTypography.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Tümünü Gör',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
