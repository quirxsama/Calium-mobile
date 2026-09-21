import 'package:flutter/material.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_typography.dart';

/// A row containing a section [title] and an optional *Tümünü Gör* action.
///
/// Used at the top of horizontal list sections on the Home, Discover, and
/// similar screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.onSeeAll, super.key});

  /// Section title displayed on the left.
  final String title;

  /// When non-null a "Tümünü Gör" text button is rendered on the right.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: AppTypography.headlineMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (onSeeAll != null)
          IconButton(
            tooltip: '$title — tümünü gör',
            onPressed: onSeeAll,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}
