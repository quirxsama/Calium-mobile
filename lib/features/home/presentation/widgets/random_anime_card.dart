import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';

class RandomAnimeCard extends StatefulWidget {
  const RandomAnimeCard({
    required this.animes,
    super.key,
  });

  final List<AnimeEntity> animes;

  @override
  State<RandomAnimeCard> createState() => _RandomAnimeCardState();
}

class _RandomAnimeCardState extends State<RandomAnimeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickRandom() async {
    if (widget.animes.isEmpty) return;

    _controller.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    final random = Random();
    final selected = widget.animes[random.nextInt(widget.animes.length)];

    context.push('/anime/${selected.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GlassContainer(
        borderRadius: AppSpacing.borderRadiusLg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withAlpha(40),
                Colors.purpleAccent.withAlpha(20),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          ),
          child: Row(
            children: [
              // Icon with glow & rotation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _controller,
                  child: const Icon(
                    Icons.casino_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ne İzleyeceğine Karar Veremedin mi?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Şansını dene, Calium sana harika bir anime önersin!',
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(200),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Zar At CTA Button
              ElevatedButton.icon(
                onPressed: _pickRandom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withAlpha(120),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.black),
                label: const Text(
                  'Zar At',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
