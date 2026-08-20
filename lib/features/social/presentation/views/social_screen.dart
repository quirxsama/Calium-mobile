import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';
import 'package:calium_stream/features/social/presentation/widgets/user_search_sheet.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SocialBloc>().add(LoadSocialDataRequested());
  }

  void _openUserSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const UserSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Sosyal',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Kullanıcı Ara & Takip Et',
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: _openUserSearch,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_search_rounded),
        label: const Text('Kullanıcı Ara', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _openUserSearch,
      ),
      body: BlocBuilder<SocialBloc, SocialState>(
        builder: (context, state) {
          if (state is SocialLoading || state is SocialInitial) {
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: 5,
              itemBuilder: (_, _) => const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: ShimmerPlaceholder(height: 70),
              ),
            );
          }

          if (state is SocialLoaded) {
            if (state.friends.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 54, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz Takip Ettiğiniz Arkadaşınız Yok',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Diğer anime severleri bulmak ve takip etmek için sağ üstteki arama butonunu kullanabilirsiniz.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _openUserSearch,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                        label: const Text('Arkadaş Bul & Takip Et', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<SocialBloc>().add(LoadSocialDataRequested());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: state.friends.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final friend = state.friends[index];
                  return _buildFriendTile(context, friend);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFriendTile(BuildContext context, SocialFriendEntity friend) {
    final hasAvatar = friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty;

    return InkWell(
      onTap: () {
        context.push('/profile/${friend.username}');
      },
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar with online status badge
            Stack(
              children: [
                if (hasAvatar)
                  AppCachedImage(
                    imageUrl: friend.avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(20),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.surfaceElevated,
                    child: Text(
                      friend.username.isNotEmpty ? friend.username[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: friend.isOnline ? AppColors.successGreen : AppColors.textMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Username & Live Activity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName ?? friend.username,
                    style: AppTypography.titleSmall.copyWith(color: Colors.white),
                  ),
                  Text(
                    friend.activityText != null
                        ? 'İzliyor: ${friend.activityText}'
                        : (friend.isOnline ? 'Çevrimiçi' : 'Çevrimdışı'),
                    style: AppTypography.caption.copyWith(
                      color: friend.activityText != null ? AppColors.primary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}

