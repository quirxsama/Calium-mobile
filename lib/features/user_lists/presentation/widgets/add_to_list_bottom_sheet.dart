import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/user_lists/presentation/bloc/user_lists_bloc.dart';
import 'package:calium_stream/features/user_lists/presentation/widgets/create_list_dialog.dart';

class AddToListBottomSheet extends StatelessWidget {
  const AddToListBottomSheet({
    required this.animeId,
    required this.animeName,
    this.poster,
    super.key,
  });

  final String animeId;
  final String animeName;
  final String? poster;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Listeye Ekle',
                  style: AppTypography.headlineMedium.copyWith(fontSize: 18),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                  label: const Text('Yeni Liste', style: TextStyle(color: AppColors.primary)),
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
            ),
            const SizedBox(height: AppSpacing.md),
            BlocBuilder<UserListsBloc, UserListsState>(
              builder: (context, state) {
                if (state is UserListsLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                if (state is UserListsLoaded) {
                  if (state.myLists.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Henüz bir listeniz yok. Yukarıdan yeni liste oluşturabilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.myLists.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final list = state.myLists[index];
                      final containsAnime = list.items.any((it) => it.animeId == animeId);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.playlist_add_check_rounded, color: AppColors.primary),
                        title: Text(list.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${list.itemCount} anime · ${list.isPublic ? 'Herkese Açık' : 'Gizli'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: IconButton(
                          icon: Icon(
                            containsAnime ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            color: containsAnime ? AppColors.successGreen : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            if (containsAnime) {
                              context.read<UserListsBloc>().add(
                                    RemoveAnimeFromListRequested(
                                      listId: list.id,
                                      animeId: animeId,
                                    ),
                                  );
                            } else {
                              context.read<UserListsBloc>().add(
                                    AddAnimeToListRequested(
                                      listId: list.id,
                                      animeId: animeId,
                                      animeName: animeName,
                                      poster: poster,
                                    ),
                                  );
                            }
                          },
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
