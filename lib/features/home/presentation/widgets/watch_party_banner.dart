import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';

class WatchPartyBanner extends StatelessWidget {
  const WatchPartyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: InkWell(
        onTap: () => context.go('/social'),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        child: GlassContainer(
          borderRadius: AppSpacing.borderRadiusLg,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(50),
                      Colors.cyanAccent.withAlpha(30),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Birlikte İzle (Watch Party)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(40),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.redAccent.withAlpha(120), width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.redAccent, size: 6),
                              SizedBox(width: 3),
                              Text(
                                'CANLI',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Arkadaşlarınla anlık oda aç veya açık odalara katıl!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
