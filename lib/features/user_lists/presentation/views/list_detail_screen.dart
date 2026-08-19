import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';
import 'package:calium_stream/features/user_lists/domain/repositories/user_lists_repository.dart';
import 'package:calium_stream/features/user_lists/presentation/bloc/user_lists_bloc.dart';

class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({required this.listId, super.key});

  final String listId;

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  UserListEntity? _list;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await GetIt.I<UserListsRepository>().getListDetails(widget.listId);
    res.fold(
      (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
      (list) => setState(() {
        _list = list;
        _isLoading = false;
      }),
    );
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
          _list?.name ?? 'Liste Detayı',
          style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_list != null)
            IconButton(
              icon: Icon(
                _list!.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _list!.isLiked ? AppColors.accentCrimson : Colors.white,
              ),
              onPressed: () {
                context.read<UserListsBloc>().add(ToggleLikeListRequested(widget.listId));
                setState(() {
                  _list = UserListEntity(
                    id: _list!.id,
                    userId: _list!.userId,
                    name: _list!.name,
                    description: _list!.description,
                    isPublic: _list!.isPublic,
                    itemCount: _list!.itemCount,
                    likeCount: _list!.isLiked ? _list!.likeCount - 1 : _list!.likeCount + 1,
                    isLiked: !_list!.isLiked,
                    items: _list!.items,
                    creatorUsername: _list!.creatorUsername,
                    createdAt: _list!.createdAt,
                  );
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.accentCrimson, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTypography.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDetails,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _list == null
                  ? const SizedBox.shrink()
                  : CustomScrollView(
                      slivers: [
                        // Description Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.screenPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_list!.description != null && _list!.description!.isNotEmpty)
                                  Text(_list!.description!, style: AppTypography.bodyMedium),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Text(
                                      '${_list!.items.length} Anime',
                                      style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_list!.creatorUsername != null)
                                      Text(
                                        'Oluşturan: @${_list!.creatorUsername}',
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Anime Grid
                        if (_list!.items.isEmpty)
                          const SliverFillRemaining(
                            child: Center(
                              child: Text(
                                'Bu listede henüz anime bulunmuyor.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.55,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _list!.items[index];
                                  return AnimePosterCard(
                                    id: item.animeId,
                                    title: item.name,
                                    posterUrl: item.poster ?? '',
                                    rating: 0,
                                    onTap: () {
                                      context.push('/anime/${item.animeId}');
                                    },
                                  );
                                },
                                childCount: _list!.items.length,
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
