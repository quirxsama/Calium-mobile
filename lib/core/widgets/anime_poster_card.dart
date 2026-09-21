import 'package:flutter/material.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';

/// A focusable poster tile with consistent two-line titles.
class AnimePosterCard extends StatelessWidget {
  const AnimePosterCard({
    required this.id,
    required this.title,
    required this.posterUrl,
    this.fallbackUrls = const [],
    this.episodeBadge,
    this.rating,
    this.onTap,
    this.width,
    super.key,
  });

  final String id;
  final String title;
  final String posterUrl;
  final List<String> fallbackUrls;
  final String? episodeBadge;
  final double? rating;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Poster Image (Expanded so it scales safely inside Grid/Flex) ──
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppCachedImage(
                  imageUrl: posterUrl,
                  fallbackUrls: fallbackUrls,
                  fit: BoxFit.cover,
                ),

                // Rating badge – top right
                if (rating != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: _RatingBadge(rating: rating!),
                  ),

                // Episode badge – bottom left
                if (episodeBadge != null)
                  Positioned(
                    bottom: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: _EpisodeBadge(label: episodeBadge!),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Title ────────────────────────────────────────────────
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(14) * 2.6,
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (width != null) {
      card = SizedBox(width: width, child: card);
    }

    return RepaintBoundary(
      child: Semantics(
        button: onTap != null,
        label: title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            onTap: onTap,
            child: card,
          ),
        ),
      ),
    );
  }
}

// ─── Private Widgets ──────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(200),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 12,
            color: AppColors.ratingAmber,
          ),
          const SizedBox(width: 2),
          Text(rating.toStringAsFixed(1), style: AppTypography.badgeSmall),
        ],
      ),
    );
  }
}

class _EpisodeBadge extends StatelessWidget {
  const _EpisodeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(220),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.badgeSmall.copyWith(color: AppColors.background),
      ),
    );
  }
}
