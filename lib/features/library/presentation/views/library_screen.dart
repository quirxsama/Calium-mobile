import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/services/tracking_service.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/core/widgets/adaptive_poster_grid.dart';
import 'package:calium_stream/core/widgets/app_content_frame.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/app_status_view.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/core/utils/episode_utils.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({this.initialTab = 0, super.key});
  final int initialTab;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    context.read<LibraryBloc>().add(LoadLibraryRequested());
    context.read<AuthBloc>().add(CheckAuthRequested());
  }

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab &&
        _tabController.index != widget.initialTab) {
      _tabController.animateTo(widget.initialTab.clamp(0, 3));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshLibrary() async {
    final bloc = context.read<LibraryBloc>();
    final completed = bloc.stream.firstWhere(
      (state) =>
          state is LibraryFailureState ||
          (state is LibraryLoaded && !state.isRefreshing),
    );
    bloc.add(LoadLibraryRequested());
    await completed;
  }

  Widget _collectionState(
    LibraryState state,
    Widget content,
    String error,
    bool hasItems,
  ) {
    if (state is LibraryInitial || state is LibraryLoading) {
      return const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Kitaplık yükleniyor'),
      );
    }
    final message = state is LibraryFailureState ? state.message : error;
    if (message.isNotEmpty && !hasItems) {
      return AppStatusView(
        title: 'İçerik yüklenemedi',
        message: message,
        icon: Icons.error_outline_rounded,
        actions: [
          FilledButton(
            onPressed: _refreshLibrary,
            child: const Text('Yeniden dene'),
          ),
        ],
      );
    }
    return Column(
      children: [
        if (state is LibraryLoaded && state.isRefreshing)
          const LinearProgressIndicator(semanticsLabel: 'Kitaplık yenileniyor'),
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  message,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _refreshLibrary,
                  child: const Text('Yeniden dene'),
                ),
              ],
            ),
          ),
        Expanded(child: content),
      ],
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
          'Kitaplık',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
              final downloadingTasks = tasks
                  .where((t) => t.status == DownloadStatus.downloading)
                  .toList();
              final isDownloading = downloadingTasks.isNotEmpty;
              final totalProgress = isDownloading
                  ? downloadingTasks
                            .map((t) => t.progress)
                            .reduce((a, b) => a + b) /
                        downloadingTasks.length
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
                      color: isDownloading
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                onPressed: () => context.push('/downloads'),
              );
            },
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => context.push('/settings'),
          ),
        ],

        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
            Tab(text: 'Kütüphanem'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<LibraryBloc, LibraryState>(
          listenWhen: (previous, current) =>
              current is LibraryLoaded &&
              current.errorMessage.isNotEmpty &&
              (previous is! LibraryLoaded ||
                  previous.errorMessage != current.errorMessage),
          listener: (context, state) {
            if (state is LibraryLoaded) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.errorMessage)));
            }
          },
          builder: (context, libraryState) {
            final favorites = (libraryState is LibraryLoaded)
                ? libraryState.favorites
                : <FavoriteEntity>[];
            final history = (libraryState is LibraryLoaded)
                ? libraryState.history
                : <HistoryEntity>[];

            return TabBarView(
              controller: _tabController,
              children: [
                AppContentFrame(
                  maxWidth: 760,
                  child: _buildProfileTab(
                    context,
                    favorites.length,
                    history.length,
                  ),
                ),
                _collectionState(
                  libraryState,
                  _buildFavoritesTab(favorites),
                  libraryState is LibraryLoaded
                      ? libraryState.favoritesError
                      : '',
                  favorites.isNotEmpty,
                ),
                _collectionState(
                  libraryState,
                  _buildHistoryTab(history),
                  libraryState is LibraryLoaded
                      ? libraryState.historyError
                      : '',
                  history.isNotEmpty,
                ),
                _buildTrackingTab(),
              ],
            );
          },
        ),
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
              await _refreshLibrary();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadiusLg,
                    ),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surfaceElevated,
                        child: ClipOval(
                          child:
                              (user.avatarUrl != null &&
                                  user.avatarUrl!.isNotEmpty)
                              ? AppCachedImage(
                                  imageUrl: user.avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorWidget: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              : Text(
                                  user.username.isNotEmpty
                                      ? user.username[0].toUpperCase()
                                      : 'U',
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
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),

                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusMd,
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceAround,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _buildStatItem('Favoriler', favCount.toString()),
                            _buildStatItem('İzlenenler', histCount.toString()),
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
                    borderRadius: BorderRadius.circular(
                      AppSpacing.borderRadiusMd,
                    ),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.cloud_done_rounded,
                          color: AppColors.successGreen,
                        ),
                        title: const Text(
                          'Hesap eşitlemesi',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Favoriler ve izleme geçmişi',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            context.read<LibraryBloc>().add(SyncRequested());
                          },
                          child: const Text('Eşitle'),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        leading: const Icon(
                          Icons.history_toggle_off_rounded,
                          color: AppColors.ratingAmber,
                        ),
                        title: const Text(
                          'İzleme Geçmişini Sıfırla',
                          style: TextStyle(color: Colors.white),
                        ),
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
                      side: const BorderSide(
                        color: AppColors.accentCrimson,
                        width: 0.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadiusMd,
                        ),
                      ),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
          child: SingleChildScrollView(
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
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadiusMd,
                          ),
                        ),
                      ),
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text(
                        'Giriş Yap / Kayıt Ol',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
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
        title: const Text(
          'Çıkış Yapılsın mı?',
          style: TextStyle(color: Colors.white),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCrimson,
            ),
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
        title: const Text(
          'Geçmiş Temizlensin mi?',
          style: TextStyle(color: Colors.white),
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCrimson,
            ),
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
      return AppStatusView(
        title: 'Henüz favori eklemedin',
        message: 'Beğendiğin animeleri detay sayfasından favorilerine ekleyebilirsin.',
        icon: Icons.bookmark_border_rounded,
        actions: [
          FilledButton(
            onPressed: () => context.go('/explore'),
            child: const Text('Anime keşfet'),
          ),
          TextButton(onPressed: _refreshLibrary, child: const Text('Yenile')),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLibrary,
      child: AdaptivePosterGrid(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
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
      return AppStatusView(
        title: 'İzleme geçmişin boş',
        message: 'İzlediğin bölümler burada listelenecek.',
        icon: Icons.history_rounded,
        actions: [
          FilledButton(
            onPressed: () => context.go('/explore'),
            child: const Text('Anime keşfet'),
          ),
          TextButton(onPressed: _refreshLibrary, child: const Text('Yenile')),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshLibrary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  imageUrl: item.episodeThumb.isNotEmpty
                      ? item.episodeThumb
                      : item.posterUrl,
                  fallbackUrls: [
                    if (item.episodeThumb.isNotEmpty) item.posterUrl,
                  ],
                  width: MediaQuery.sizeOf(context).width < 400 ? 64 : 100,
                  height: 68,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusSm,
                  ),
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
                            final cleanEpId =
                                (item.episodeId.isNotEmpty &&
                                    !item.episodeId.contains('_'))
                                ? item.episodeId
                                : '';
                            context.push(
                              '/watch/${item.animeId}?url=&title=${Uri.encodeComponent(item.animeName)}&episode=${Uri.encodeComponent(item.episodeName)}&ep=${item.episodeNumber}&s=${item.seasonNumber}&poster=${Uri.encodeComponent(item.posterUrl)}&episodeId=${Uri.encodeComponent(cleanEpId)}',
                            );
                          },
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Devam et',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(48, 48),
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

  // ─── 4. KÜTÜPHANEM SEKMESİ ──────────────────────────────────────

  Widget _buildTrackingTab() {
    return AppContentFrame(
      maxWidth: 760,
      child: const _TrackingLibraryTab(),
    );
  }
}

/// Colours mirror the web app's tracking status palette.
const Color _trackingWatchingColor = Color(0xFF60A5FA);
const Color _trackingPlannedColor = Color(0xFFA78BFA);

/// "Kütüphanem" tab: the cross-device tracking library (status + progress).
class _TrackingLibraryTab extends StatefulWidget {
  const _TrackingLibraryTab();

  @override
  State<_TrackingLibraryTab> createState() => _TrackingLibraryTabState();
}

class _TrackingLibraryTabState extends State<_TrackingLibraryTab> {
  static const Map<String, String> _filters = {
    'all': 'Tümü',
    'watching': 'İzleniyor',
    'plan_to_watch': 'Planlandı',
    'completed': 'Bitirildi',
    'dropped': 'Bırakıldı',
  };

  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  String _query = '';
  String? _loadedUser;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the tracking library the first time the tab is visible for a user.
  void _loadForUser(AuthState auth) {
    final userId = auth is Authenticated ? auth.user.id : null;
    if (userId == _loadedUser) return;
    _loadedUser = userId;
    if (userId != null) TrackingService.instance.refreshEntries();
  }

  Future<void> _handleSync() async {
    final tracking = TrackingService.instance;
    await tracking.triggerSync();
    await tracking.refreshEntries();
  }

  void _clearSearch() {
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  void _clearFilters() {
    setState(() {
      _filter = 'all';
      _query = '';
      _searchController.clear();
    });
  }

  List<Map<String, dynamic>> _filteredEntries(
    List<Map<String, dynamic>> entries,
  ) {
    final query = _query.trim().toLowerCase();
    return entries.where((entry) {
      if (_filter != 'all' && TrackingService.entryStatus(entry) != _filter) {
        return false;
      }
      if (query.isNotEmpty) {
        final title = entry['title']?.toString().toLowerCase() ?? '';
        if (!title.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  void _openEntry(Map<String, dynamic> entry) {
    final sourceId = entry['sourceId']?.toString() ?? '';
    if (sourceId.isNotEmpty) {
      context.push('/anime/${Uri.encodeComponent(sourceId)}');
      return;
    }
    final title = entry['title']?.toString() ?? '';
    if (title.isEmpty) return;
    context.push('/search?q=${Uri.encodeComponent(title)}');
  }

  Future<void> _confirmRemove(Map<String, dynamic> entry) async {
    final title = entry['title']?.toString() ?? 'Bu anime';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'Kütüphaneden kaldırılsın mı?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '"$title" takip listenden kaldırılacak.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCrimson,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TrackingService.instance.removeEntry(entry);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'watching':
        return _trackingWatchingColor;
      case 'plan_to_watch':
        return _trackingPlannedColor;
      case 'completed':
        return AppColors.successGreen;
      case 'dropped':
        return AppColors.accentCrimson;
      case 'on_hold':
        return AppColors.ratingAmber;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) {
        if (auth is AuthInitial || auth is AuthLoading) {
          return const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Kütüphane yükleniyor'),
          );
        }
        if (auth is! Authenticated) {
          _loadForUser(auth);
          return _buildLoginGate();
        }
        _loadForUser(auth);
        return ListenableBuilder(
          listenable: TrackingService.instance,
          builder: (context, _) => _buildLibrary(TrackingService.instance),
        );
      },
    );
  }

  Widget _buildLibrary(TrackingService tracking) {
    final entries = tracking.entries;
    final filtered = _filteredEntries(entries);
    final error = tracking.lastError;

    if (!tracking.entriesLoaded && entries.isEmpty && error == null) {
      return _buildSkeleton();
    }
    if (entries.isEmpty && error != null) {
      return AppStatusView(
        title: 'Kütüphane yüklenemedi',
        message: error,
        icon: Icons.error_outline_rounded,
        actions: [
          FilledButton(
            onPressed: _handleSync,
            child: const Text('Yeniden dene'),
          ),
        ],
      );
    }

    final Widget content;
    if (entries.isEmpty) {
      content = _buildEmptyState();
    } else if (filtered.isEmpty) {
      content = _buildNoResults();
    } else {
      content = _buildEntryList(filtered, tracking);
    }

    return RefreshIndicator(
      onRefresh: () => tracking.refreshEntries(),
      color: AppColors.primary,
      child: Column(
        children: [
          _buildHeader(tracking),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.accentCrimson,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleSync,
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildHeader(TrackingService tracking) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Kütüphanende ara...',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Aramayı temizle',
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: _clearSearch,
                          ),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Eşitle',
                onPressed: tracking.isSyncing ? null : _handleSync,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceDark,
                  side: const BorderSide(color: AppColors.border, width: 0.5),
                ),
                icon: tracking.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in _filters.entries)
                  _buildFilterChip(filter.key, filter.value),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _filter == key;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _filter = key),
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: 0.8,
        ),
        labelStyle: AppTypography.bodySmall.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) =>
          const ShimmerPlaceholder(height: 104, borderRadius: AppSpacing.borderRadiusMd),
    );
  }

  Widget _buildEmptyState() {
    return AppStatusView(
      title: 'Kütüphanen boş',
      message:
          'Takip ettiğin animeler burada listelenecek. Anime detay sayfasından kütüphanene ekleyebilirsin.',
      icon: Icons.collections_bookmark_outlined,
      actions: [
        FilledButton(
          onPressed: () => context.go('/explore'),
          child: const Text('Keşfete göz at'),
        ),
        TextButton(
          onPressed: () => TrackingService.instance.refreshEntries(),
          child: const Text('Yenile'),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return AppStatusView(
      title: 'Sonuç bulunamadı',
      message: 'Araman veya filtrenle eşleşen anime yok.',
      icon: Icons.search_off_rounded,
      actions: [
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Filtreleri temizle'),
        ),
      ],
    );
  }

  Widget _buildEntryList(
    List<Map<String, dynamic>> entries,
    TrackingService tracking,
  ) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: ScrollCacheExtent.pixels(500),
      addRepaintBoundaries: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          _buildEntryCard(entries[index], tracking),
    );
  }

  Widget _buildEntryCard(
    Map<String, dynamic> entry,
    TrackingService tracking,
  ) {
    final id = entry['id']?.toString() ?? '';
    final title = entry['title']?.toString() ?? 'Bilinmeyen anime';
    final status = TrackingService.entryStatus(entry);
    final progress = TrackingService.entryProgress(entry);
    final total = TrackingService.entryTotalEpisodes(entry);
    final score = TrackingService.entryScore(entry);
    final poster = TrackingService.entryPoster(entry);
    final busy = tracking.isEntryBusy(id);
    final statusColor = _statusColor(status);
    final hasTotal = total != null && total > 0;
    final canDecrease = !busy && progress > 0;
    final canIncrease = !busy && (!hasTotal || progress < total);

    return Material(
      color: AppColors.surfaceDark,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: InkWell(
        onTap: () => _openEntry(entry),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                child: AppCachedImage(
                  imageUrl: poster,
                  width: 64,
                  height: 92,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 64,
                    height: 92,
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (score > 0) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _buildScoreBadge(score),
                        ],
                        _buildOverflowMenu(entry, status, busy),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(status, statusColor),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            hasTotal
                                ? '$progress/$total bölüm'
                                : '$progress bölüm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildProgressButton(
                          icon: Icons.remove_rounded,
                          tooltip: 'Bölüm azalt',
                          onPressed: canDecrease
                              ? () => tracking.setEntryProgress(
                                  entry,
                                  progress - 1,
                                )
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: hasTotal
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: (progress / total).clamp(0.0, 1.0),
                                      backgroundColor: AppColors.surfaceElevated,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
                                      minHeight: 4,
                                      semanticsLabel: 'Bölüm ilerlemesi',
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        _buildProgressButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Bölüm artır',
                          onPressed: canIncrease
                              ? () => tracking.setEntryProgress(
                                  entry,
                                  progress + 1,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ratingAmber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 13,
            color: AppColors.ratingAmber,
          ),
          const SizedBox(width: 2),
          Text(
            (score / 10).toStringAsFixed(1),
            style: AppTypography.caption.copyWith(
              color: AppColors.ratingAmber,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    final label = TrackingService.statusLabels[status] ??
        (status.isEmpty ? 'Durum yok' : status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.8),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProgressButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.surfaceElevated,
        disabledBackgroundColor: AppColors.surfaceElevated.withValues(
          alpha: 0.4,
        ),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      icon: Icon(
        icon,
        color: onPressed == null ? AppColors.textMuted : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOverflowMenu(
    Map<String, dynamic> entry,
    String status,
    bool busy,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Seçenekler',
      enabled: !busy,
      color: AppColors.surfaceDark,
      onSelected: (value) {
        if (value == 'remove') {
          _confirmRemove(entry);
          return;
        }
        if (value.startsWith('status:')) {
          final next = value.substring('status:'.length);
          if (next != status) {
            TrackingService.instance.setEntryStatus(entry, next);
          }
        }
      },
      itemBuilder: (context) => [
        for (final key in TrackingService.statusOrder)
          PopupMenuItem<String>(
            value: 'status:$key',
            height: 44,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: key == status
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.primary,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  TrackingService.statusLabels[key] ?? key,
                  style: AppTypography.bodySmall.copyWith(
                    color: key == status
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'remove',
          height: 44,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.accentCrimson,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Kütüphaneden kaldır',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentCrimson,
                ),
              ),
            ],
          ),
        ),
      ],
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLoginGate() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Kütüphaneni görmek için giriş yap',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Takip ettiğin animeler, izleme durumların ve bölüm ilerlemen burada listelenir.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Giriş Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
