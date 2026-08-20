import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';

class InPlayerEpisodesSheet extends StatefulWidget {
  const InPlayerEpisodesSheet({
    required this.episodes,
    required this.currentEpisodeNumber,
    required this.currentSeasonNumber,
    required this.onEpisodeSelected,
    super.key,
  });

  final List<EpisodeEntity> episodes;
  final int currentEpisodeNumber;
  final int currentSeasonNumber;
  final ValueChanged<EpisodeEntity> onEpisodeSelected;

  @override
  State<InPlayerEpisodesSheet> createState() => _InPlayerEpisodesSheetState();
}

class _InPlayerEpisodesSheetState extends State<InPlayerEpisodesSheet> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentIndex = widget.episodes.indexWhere(
        (e) => e.episodeNumber == widget.currentEpisodeNumber,
      );
      if (currentIndex > 2 && _scrollController.hasClients) {
        final targetOffset = (currentIndex - 1) * 64.0;
        _scrollController.jumpTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEpisodes = widget.episodes.where((ep) {
      if (_filterQuery.isEmpty) return true;
      final title = (ep.title ?? '').toLowerCase();
      final numStr = ep.episodeNumber.toString();
      final q = _filterQuery.toLowerCase();
      return title.contains(q) || numStr.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bölümler (Sezon ${widget.currentSeasonNumber})',
                style: AppTypography.headlineMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${widget.episodes.length} Bölüm',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Search / Filter Input
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Bölüm ara veya no yaz...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) => setState(() => _filterQuery = val.trim()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: filteredEpisodes.isEmpty
                ? const Center(
                    child: Text(
                      'Bölüm bulunamadı.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    scrollCacheExtent: ScrollCacheExtent.pixels(500),
                    itemCount: filteredEpisodes.length,
                    separatorBuilder: (_, _) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final ep = filteredEpisodes[index];
                      final isCurrent = ep.episodeNumber == widget.currentEpisodeNumber;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primary : AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(120),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCurrent
                                ? const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22)
                                : Text(
                                    '${ep.episodeNumber}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(
                          ep.title ?? 'Bölüm ${ep.episodeNumber}',
                          style: TextStyle(
                            color: isCurrent ? AppColors.primary : Colors.white,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: ep.isFiller
                            ? const Text(
                                'Dolgu (Filler)',
                                style: TextStyle(color: AppColors.ratingAmber, fontSize: 11),
                              )
                            : null,
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary, width: 0.8),
                                ),
                                child: const Text(
                                  'Oynatılıyor',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isCurrent) {
                            widget.onEpisodeSelected(ep);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
