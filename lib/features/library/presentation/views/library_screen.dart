import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<LibraryBloc>().add(LoadLibraryRequested());
    context.read<AuthBloc>().add(CheckAuthRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Kitaplık & Profil',
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profilim',
            icon: const Icon(Icons.person_rounded, color: AppColors.primary),
            onPressed: () => context.push('/profile'),
          ),
          StreamBuilder<List<DownloadTaskEntity>>(
            stream: DownloadService.instance.tasksStream,
            initialData: DownloadService.instance.currentTasks,
            builder: (context, snapshot) {
              final tasks = snapshot.data ?? [];
              final downloadingTasks = tasks.where((t) => t.status == DownloadStatus.downloading).toList();
              final isDownloading = downloadingTasks.isNotEmpty;
              final totalProgress = isDownloading 
                  ? downloadingTasks.map((t) => t.progress).reduce((a, b) => a + b) / downloadingTasks.length 
                  : 0.0;

              return IconButton(
                tooltip: 'İndirilenler',
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isDownloading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: totalProgress > 0 ? totalProgress : null,
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    Icon(
                      Icons.download_for_offline_rounded, 
                      color: isDownloading ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ],
                ),
                onPressed: () => context.push('/downloads'),
              );
            },
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () => context.push('/settings'),
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Favoriler'),
            Tab(text: 'Geçmiş'),
          ],
        ),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, libraryState) {
          final favorites = (libraryState is LibraryLoaded) ? libraryState.favorites : <FavoriteEntity>[];
          final history = (libraryState is LibraryLoaded) ? libraryState.history : <HistoryEntity>[];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(context, favorites.length, history.length),
              _buildFavoritesTab(favorites),
              _buildHistoryTab(history),
            ],
          );
        },
      ),
    );
  }

  // ─── 1. PROFİL SEKMESİ ──────────────────────────────────────────

  Widget _buildProfileTab(BuildContext context, int favCount, int histCount) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          final user = authState.user;
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AuthBloc>().add(CheckAuthRequested());
              context.read<LibraryBloc>().add(LoadLibraryRequested());
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surfaceElevated,
                        child: ClipOval(
                          child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                              ? AppCachedImage(
                                  imageUrl: user.avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorWidget: Text(
                                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Text(
                                  user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Display Name & Username
                      Text(
                        user.displayName ?? user.username,
                        style: AppTypography.headlineMedium.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),

                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Favoriler', favCount.toString()),
                            Container(width: 1, height: 28, color: AppColors.border),
                            _buildStatItem('İzlenenler', histCount.toString()),
                            Container(width: 1, height: 28, color: AppColors.border),
                            _buildStatItem('Rol', user.role.toUpperCase()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Settings & Sync Options
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cloud_done_rounded, color: AppColors.successGreen),
                        title: const Text('Bulut Veritabanı', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('calium.fun ile bağlı', style: TextStyle(color: AppColors.textMuted)),
                        trailing: TextButton(
                          onPressed: () {
                            context.read<LibraryBloc>().add(SyncRequested());
                          },
                          child: const Text('Eşitle'),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        leading: const Icon(Icons.history_toggle_off_rounded, color: AppColors.ratingAmber),
                        title: const Text('İzleme Geçmişini Sıfırla', style: TextStyle(color: Colors.white)),
                        onTap: () => _confirmClearHistory(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.accentCrimson,
                      side: const BorderSide(color: AppColors.accentCrimson, width: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      ),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        }

        // Loading State
        if (authState is AuthLoading || authState is AuthInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Unauthenticated State
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesabına Giriş Yap',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'İzleme geçmişini, favorilerini ve arkadaşlarını tüm cihazlarında senkronize tutmak için calium.fun hesabınla giriş yap.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      ),
                    ),
                    onPressed: () => context.push('/login'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Giriş Yap / Kayıt Ol', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Çıkış Yapılsın mı?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Oturumunuz kapatılacak. İstediğiniz zaman tekrar giriş yapabilirsiniz.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCrimson),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Çıkış'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Geçmiş Temizlensin mi?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm izleme geçmişiniz silinecektir.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentCrimson),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<LibraryBloc>().add(ClearHistoryRequested());
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  // ─── 2. FAVORİLER SEKMESİ ───────────────────────────────────────

  Widget _buildFavoritesTab(List<FavoriteEntity> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Henüz favori eklemedin',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Beğendiğin animeleri kaydetmek için anime detayından favoriye ekle.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LibraryBloc>().add(LoadLibraryRequested());
      },
      child: GridView.builder(
        scrollCacheExtent: ScrollCacheExtent.pixels(600),
        addRepaintBoundaries: true,
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final fav = favorites[index];
          return AnimePosterCard(
            id: fav.animeId,
            title: fav.name,
            posterUrl: fav.posterUrl,
            onTap: () => context.push('/anime/${fav.animeId}'),
          );
        },
      ),
    );
  }

  // ─── 3. İZLEME GEÇMİŞİ SEKMESİ ──────────────────────────────────

  Widget _buildHistoryTab(List<HistoryEntity> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'İzleme geçmişin boş',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'İzlediğin bölümler burada listelenecek.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LibraryBloc>().add(LoadLibraryRequested());
      },
      child: ListView.separated(
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
        addRepaintBoundaries: true,
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: history.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = history[index];

          return Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                AppCachedImage(
                  imageUrl: item.episodeThumb.isNotEmpty ? item.episodeThumb : item.posterUrl,
                  fallbackUrls: [
                    if (item.episodeThumb.isNotEmpty) item.posterUrl,
                  ],
                  width: 100,
                  height: 68,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.animeName,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        EpisodeUtils.formatEpisodeLabel(
                          season: item.seasonNumber,
                          episode: item.episodeNumber,
                          title: item.episodeName,
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: item.progress.clamp(0.0, 1.0),
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Resume button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            context.push(
                              '/watch/${item.animeId}?url=&title=${Uri.encodeComponent(item.animeName)}&episode=${Uri.encodeComponent(item.episodeName)}&ep=${item.episodeNumber}&s=${item.seasonNumber}&poster=${Uri.encodeComponent(item.posterUrl)}',
                            );
                          },
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Kaldığın Yerden Devam Et',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Remove from history
                IconButton(
                  tooltip: 'Geçmişten Kaldır',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    context.read<LibraryBloc>().add(
                          RemoveHistoryItemRequested(animeId: item.animeId),
                        );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
