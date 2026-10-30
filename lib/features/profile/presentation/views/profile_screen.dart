import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/glass_container.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/core/utils/navigation_utils.dart';
import 'package:calium_stream/features/profile/domain/entities/user_profile_entity.dart';
import 'package:calium_stream/features/profile/domain/repositories/profile_repository.dart';
import 'package:calium_stream/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:calium_stream/features/profile/presentation/cubit/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    this.username,
    super.key,
  });

  final String? username;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileCubit(
        repository: GetIt.I<ProfileRepository>(),
      )..loadProfile(username: username),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: const _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_rounded, color: AppColors.accentCrimson, size: 56),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTypography.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;

          return DefaultTabController(
            length: 4,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 420,
                    pinned: true,
                    backgroundColor: AppColors.surfaceDark,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => goBackOrHome(context),
                    ),
                    actions: [
                      if (profile.isOwner) ...[
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: Colors.white),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildProfileHeader(context, profile),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceDark,
                          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                        ),
                        child: const TabBar(
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          tabs: [
                            Tab(text: 'Son İzlenenler'),
                            Tab(text: 'Listeler'),
                            Tab(text: 'Hakkında'),
                            Tab(text: 'Yorumlar'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildHistoryTab(context, profile),
                  _buildListsTab(context, profile),
                  _buildAboutTab(context, profile),
                  _buildCommentsTab(context, state),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfileEntity profile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withAlpha(50),
            AppColors.surfaceDark,
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with Glowing Gradient Ring
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accentCrimson, AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(120),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SizedBox(
              width: 84,
              height: 84,
              child: ClipOval(
                child: AppCachedImage(
                  imageUrl: profile.avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: AppColors.surfaceElevated,
                    alignment: Alignment.center,
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Display Name & Username
          Text(
            profile.displayName,
            style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '@${profile.username}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),

          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              profile.bio!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 14),

          // Modern Glassmorphic Stats Row
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            borderRadius: 16.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(child: _buildStatItem('Favori', profile.favoritesCount, Icons.favorite_rounded, AppColors.accentCrimson)),
                _buildStatDivider(),
                Flexible(child: _buildStatItem('Liste', profile.listsCount, Icons.playlist_play_rounded, AppColors.primary)),
                _buildStatDivider(),
                Flexible(child: _buildStatItem('Takipçi', profile.followersCount, Icons.people_alt_rounded, Colors.purpleAccent)),
                _buildStatDivider(),
                Flexible(child: _buildStatItem('Takip', profile.followingCount, Icons.person_add_alt_1_rounded, Colors.blueAccent)),
                _buildStatDivider(),
                Flexible(child: _buildStatItem('Arkadaş', profile.friendsCount, Icons.group_rounded, Colors.tealAccent)),
              ],
            ),
          ),

          if (!profile.isOwner) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: profile.isFollowing ? AppColors.surfaceElevated : AppColors.primary,
                foregroundColor: profile.isFollowing ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              onPressed: () {
                context.read<ProfileCubit>().toggleFollow(profile.username);
              },
              child: Text(
                profile.isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 3),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 20,
      color: Colors.white12,
    );
  }

  Widget _buildHistoryTab(BuildContext context, UserProfileEntity profile) {
    if (profile.recentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              profile.isOwner ? 'Henüz izleme geçmişi yok.' : 'Kullanıcının geçmişi gizli veya boş.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: profile.recentHistory.length,
      itemBuilder: (context, index) {
        final item = profile.recentHistory[index];
        final progressRatio = (item.duration > 0) ? (item.progress / item.duration).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () {
                final cleanEpId = (item.episodeId.isNotEmpty && !item.episodeId.contains('_'))
                    ? item.episodeId
                    : '';
                context.push(
                  '/watch/${item.animeId}?title=${Uri.encodeComponent(item.animeName)}&episode=${Uri.encodeComponent(item.episodeName)}&s=${item.seasonNumber ?? 1}&ep=${item.episodeNumber ?? 1}&poster=${Uri.encodeComponent(item.poster ?? '')}&episodeId=${Uri.encodeComponent(cleanEpId)}',
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppCachedImage(
                      imageUrl: item.poster ?? '',
                      width: 70,
                      height: 95,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.animeName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          EpisodeUtils.formatEpisodeLabel(
                            season: item.seasonNumber ?? 1,
                            episode: item.episodeNumber ?? 1,
                            title: item.episodeName,
                          ),
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressRatio,
                            backgroundColor: Colors.white12,
                            color: AppColors.primary,
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
                    onPressed: () {
                      final cleanEpId = (item.episodeId.isNotEmpty && !item.episodeId.contains('_'))
                          ? item.episodeId
                          : '';
                      context.push(
                        '/watch/${item.animeId}?title=${Uri.encodeComponent(item.animeName)}&episode=${Uri.encodeComponent(item.episodeName)}&s=${item.seasonNumber ?? 1}&ep=${item.episodeNumber ?? 1}&poster=${Uri.encodeComponent(item.poster ?? '')}&episodeId=${Uri.encodeComponent(cleanEpId)}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListsTab(BuildContext context, UserProfileEntity profile) {
    if (profile.lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_remove_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              profile.isOwner ? 'Henüz liste oluşturulmamış.' : 'Kullanıcının listesi yok veya gizli.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: profile.lists.length,
      itemBuilder: (context, index) {
        final list = profile.lists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.playlist_play_rounded, color: AppColors.primary),
              ),
              title: Text(
                list.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '${list.itemCount} anime • ${list.likeCount} beğeni',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () {
                context.push('/lists/${list.id}');
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(BuildContext context, UserProfileEntity profile) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hesap Bilgileri',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 14),
              _buildInfoRow(Icons.person_outline_rounded, 'Kullanıcı Adı', '@${profile.username}'),
              const Divider(color: AppColors.border, height: 20),
              _buildInfoRow(
                Icons.calendar_month_outlined,
                'Kayıt Tarihi',
                profile.createdAt != null
                    ? '${profile.createdAt!.day}.${profile.createdAt!.month}.${profile.createdAt!.year}'
                    : 'Bilinmiyor',
              ),
              const Divider(color: AppColors.border, height: 20),
              _buildInfoRow(
                Icons.lock_outline_rounded,
                'Gizlilik',
                profile.isPrivate ? 'Gizli Profil' : 'Herkese Açık',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  String _formatCommentDate(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day} ${_monthNames[local.month - 1]} ${local.year}';
  }

  Widget _buildCommentsTab(BuildContext context, ProfileLoaded loaded) {
    final profile = loaded.profile;

    if (!profile.commentsVisible) {
      return _buildCommentsMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Bu kullanıcı yorumlarını gizlemiş.',
        description: profile.isOwner
            ? 'Yorumların şu anda gizli. Ayarlar > Gizlilik bölümünden açabilirsin.'
            : null,
        actionLabel: profile.isOwner ? 'Gizlilik Ayarları' : null,
        onAction: profile.isOwner ? () => context.push('/settings') : null,
      );
    }

    if (profile.comments.isEmpty && loaded.commentsError != null) {
      return _buildCommentsMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Yorumlar yüklenemedi.',
        description: loaded.commentsError,
        actionLabel: 'Tekrar Dene',
        onAction: () => context.read<ProfileCubit>().loadProfile(
              username: profile.username.isEmpty ? null : profile.username,
            ),
      );
    }

    if (profile.comments.isEmpty) {
      return _buildCommentsMessage(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Henüz yorum yapılmamış.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...profile.comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCommentCard(context, comment),
            ),
          ),
          if (loaded.commentsError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                loaded.commentsError!,
                style: const TextStyle(
                  color: AppColors.accentCrimson,
                  fontSize: 12,
                ),
              ),
            ),
          if (loaded.hasMoreComments)
            SizedBox(
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: loaded.isLoadingMoreComments
                    ? null
                    : () => context.read<ProfileCubit>().loadMoreComments(),
                child: loaded.isLoadingMoreComments
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        'Daha fazla yorum',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildCommentsMessage({
    required IconData icon,
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, ProfileCommentEntity comment) {
    final isEpisode = comment.isEpisodeComment;
    final dateLabel = _formatCommentDate(comment.createdAt);
    final authorName = comment.authorDisplayName?.isNotEmpty == true
        ? comment.authorDisplayName!
        : (comment.authorUsername?.isNotEmpty == true
            ? comment.authorUsername!
            : 'Kullanıcı');
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U';

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        onTap: comment.animeId.isEmpty
            ? null
            : () => context.push('/anime/${comment.animeId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: AppCachedImage(
                    imageUrl: comment.authorAvatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: 32,
                      height: 32,
                      color: AppColors.surfaceElevated,
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    authorName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (dateLabel.isNotEmpty)
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isEpisode
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isEpisode ? 'Bölüm yorumu' : 'Seri yorumu',
                style: TextStyle(
                  color:
                      isEpisode ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              comment.body.isEmpty ? '—' : comment.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Animeyi Görüntüle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
