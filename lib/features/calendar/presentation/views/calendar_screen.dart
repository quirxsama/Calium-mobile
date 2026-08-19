import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/calendar/domain/entities/calendar_day_entity.dart';
import 'package:calium_stream/features/calendar/presentation/bloc/calendar_bloc.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CalendarBloc>().add(LoadCalendarRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Yayın Takvimi',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading || state is CalendarInitial) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is CalendarFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.accentCrimson, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CalendarBloc>().add(LoadCalendarRequested()),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is CalendarLoaded) {
            if (state.days.isEmpty) {
              return const Center(
                child: Text('Takvimde gösterilecek içerik bulunamadı.', style: TextStyle(color: AppColors.textMuted)),
              );
            }

            return DefaultTabController(
              length: state.days.length,
              child: Column(
                children: [
                  // Day Tabs
                  TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    tabs: state.days.map((d) {
                      return Tab(text: d.dayName ?? d.title);
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Content Grid per Day
                  Expanded(
                    child: TabBarView(
                      children: state.days.map((day) {
                        return _DayItemsGrid(day: day);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DayItemsGrid extends StatelessWidget {
  const _DayItemsGrid({required this.day});

  final CalendarDayEntity day;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      cacheExtent: 500,
      addRepaintBoundaries: true,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: day.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = day.items[index];
        return GestureDetector(
          onTap: () {
            if (item.animeId.isNotEmpty) {
              context.push('/anime/${item.animeId}');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                  child: SizedBox(
                    width: 70,
                    height: 95,
                    child: AppCachedImage(
                      imageUrl: item.posterUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        item.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item.seasonNumber != null || item.episodeNumber != null)
                        Text(
                          '${item.seasonNumber != null ? '${item.seasonNumber}. Sezon ' : ''}${item.episodeNumber != null ? '· ${item.episodeNumber}. Bölüm' : ''}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
