import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/features/user_lists/domain/entities/user_list_entity.dart';
import 'package:calium_stream/features/user_lists/presentation/bloc/user_lists_bloc.dart';
import 'package:calium_stream/features/user_lists/presentation/widgets/create_list_dialog.dart';

class UserListsScreen extends StatefulWidget {
  const UserListsScreen({super.key});

  @override
  State<UserListsScreen> createState() => _UserListsScreenState();
}

class _UserListsScreenState extends State<UserListsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserListsBloc>().add(LoadUserListsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Listelerim & Keşfet',
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CreateListDialog(
                    onCreate: (name, desc, isPub) {
                      context.read<UserListsBloc>().add(
                            CreateUserListRequested(
                              name: name,
                              description: desc,
                              isPublic: isPub,
                            ),
                          );
                    },
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Listelerim'),
              Tab(text: 'Topluluk Listeleri'),
            ],
          ),
        ),
        body: BlocBuilder<UserListsBloc, UserListsState>(
          builder: (context, state) {
            if (state is UserListsLoading || state is UserListsInitial) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is UserListsFailure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.accentCrimson, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message, style: AppTypography.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<UserListsBloc>().add(LoadUserListsRequested()),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            if (state is UserListsLoaded) {
              return TabBarView(
                children: [
                  _ListGrid(lists: state.myLists, isMyLists: true),
                  _ListGrid(lists: state.publicLists, isMyLists: false),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ListGrid extends StatelessWidget {
  const _ListGrid({required this.lists, required this.isMyLists});

  final List<UserListEntity> lists;
  final bool isMyLists;

  @override
  Widget build(BuildContext context) {
    if (lists.isEmpty) {
      return Center(
        child: Text(
          isMyLists ? 'Henüz liste oluşturmadınız.' : 'Topluluk listesi bulunamadı.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      cacheExtent: 500,
      addRepaintBoundaries: true,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: lists.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final list = lists[index];
        final firstPoster = list.items.isNotEmpty ? list.items.first.poster : null;

        return GestureDetector(
          onTap: () {
            context.push('/lists/${list.id}');
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
                // Thumbnail or list placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                  child: Container(
                    width: 70,
                    height: 90,
                    color: AppColors.surfaceElevated,
                    child: firstPoster != null
                        ? AppCachedImage(imageUrl: firstPoster, fit: BoxFit.cover)
                        : const Icon(Icons.playlist_play_rounded, color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (list.description != null && list.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          list.description!,
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.movie_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${list.itemCount} anime', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(width: 12),
                          Icon(Icons.favorite_rounded, size: 14, color: AppColors.accentCrimson),
                          const SizedBox(width: 4),
                          Text('${list.likeCount}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          if (!isMyLists && list.creatorUsername != null) ...[
                            const SizedBox(width: 12),
                            Text('@${list.creatorUsername}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ],
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
