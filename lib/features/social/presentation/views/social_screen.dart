import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_cached_image.dart';
import 'package:calium_stream/core/widgets/shimmer_placeholder.dart';
import 'package:calium_stream/features/social/domain/entities/app_notification_entity.dart';
import 'package:calium_stream/features/social/domain/entities/follow_request_entity.dart';
import 'package:calium_stream/features/social/domain/entities/room_entity.dart';
import 'package:calium_stream/features/social/presentation/bloc/social_bloc.dart';
import 'package:calium_stream/features/social/presentation/widgets/user_search_sheet.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SocialBloc>().add(LoadSocialDataRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final totalBadge = (state is SocialLoaded) ? state.totalBadgeCount : 0;
        final friendsCount = (state is SocialLoaded) ? state.friends.length : 0;

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
                icon: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                ),
                onPressed: _openUserSearch,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text('Arkadaşlar ($friendsCount)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_rounded, size: 18),
                      const SizedBox(width: 6),
                      const Text('İstekler & Bildirim'),
                      if (totalBadge > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentCrimson,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalBadge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.person_search_rounded),
            label: const Text(
              'Kullanıcı Ara',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _openUserSearch,
          ),
          body: (state is SocialLoading || state is SocialInitial)
              ? ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  itemCount: 5,
                  itemBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerPlaceholder(height: 70),
                  ),
                )
              : (state is SocialLoaded)
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    // ─── 1. Friends Tab ──────────────────────────────
                    _buildFriendsTab(context, state),

                    // ─── 2. Requests & Notifications Tab ─────────────
                    _buildRequestsAndNotificationsTab(context, state),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildFriendsTab(BuildContext context, SocialLoaded state) {
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
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
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
                'Diğer anime severleri bulmak ve takip etmek için sağ alttaki arama butonunu kullanabilirsiniz.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openUserSearch,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: const Text(
                  'Arkadaş Bul & Takip Et',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

  Widget _buildRequestsAndNotificationsTab(
    BuildContext context,
    SocialLoaded state,
  ) {
    final requests = state.followRequests;
    final notifications = state.notifications;

    if (requests.isEmpty && notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<SocialBloc>().add(LoadSocialDataRequested());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Yeni İstek veya Bildirim Yok',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Takip istekleri ve favori animelerinizin yeni bölümleri burada görünecek.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<SocialBloc>().add(LoadSocialDataRequested());
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ─── 1. Follow Requests Section ─────────────────────────────
          if (requests.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.person_pin_circle_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gelen Takip İstekleri (${requests.length})',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...requests.map((req) => _buildFollowRequestCard(context, req)),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ─── 2. Notifications Section ───────────────────────────────
          if (notifications.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bildirimler',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        context.read<SocialBloc>().add(
                          MarkNotificationsReadRequested(),
                        );
                      },
                      child: const Text(
                        'Okundu Say',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: const Text(
                              'Bildirimler Silinsin mi?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Tüm bildirim geçmişiniz kalıcı olarak temizlenecektir.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text(
                                  'Vazgeç',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  context.read<SocialBloc>().add(
                                    ClearNotificationsRequested(),
                                  );
                                },
                                child: const Text(
                                  'Temizle',
                                  style: TextStyle(
                                    color: AppColors.accentCrimson,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Temizle',
                        style: TextStyle(
                          color: AppColors.accentCrimson,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...notifications.map((n) => _buildNotificationCard(context, n)),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowRequestCard(
    BuildContext context,
    FollowRequestEntity req,
  ) {
    final hasAvatar = req.avatarUrl != null && req.avatarUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        children: [
          // Requester Avatar
          if (hasAvatar)
            AppCachedImage(
              imageUrl: req.avatarUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(22),
            )
          else
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceElevated,
              child: Text(
                req.username.isNotEmpty ? req.username[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Requester Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.displayName ?? req.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@${req.username}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Accept Button
          IconButton(
            tooltip: 'Kabul Et',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.successGreen.withAlpha(35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.check_rounded,
              color: AppColors.successGreen,
              size: 20,
            ),
            onPressed: () {
              context.read<SocialBloc>().add(
                RespondFollowRequestRequested(
                  username: req.username,
                  accept: true,
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${req.displayName ?? req.username} takip isteği kabul edildi.',
                  ),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 6),

          // Decline Button
          IconButton(
            tooltip: 'Reddet',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accentCrimson.withAlpha(35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.accentCrimson,
              size: 20,
            ),
            onPressed: () {
              context.read<SocialBloc>().add(
                RespondFollowRequestRequested(
                  username: req.username,
                  accept: false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotificationEntity n) {
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;

    if (n.type == 'follow') {
      iconData = Icons.person_add_rounded;
      iconColor = const Color(0xFF02A9FF);
    } else if (n.type == 'follow_request') {
      iconData = Icons.person_pin_circle_rounded;
      iconColor = Colors.orangeAccent;
    } else if (n.type == 'follow_accepted') {
      iconData = Icons.how_to_reg_rounded;
      iconColor = AppColors.successGreen;
    } else if (n.type == 'new_episode') {
      iconData = Icons.play_circle_fill_rounded;
      iconColor = AppColors.primary;
    } else if (n.type == 'room_invite') {
      iconData = Icons.tv_rounded;
      iconColor = Colors.purpleAccent;
    }

    return InkWell(
      onTap: () {
        if (n.animeId != null && n.animeId!.isNotEmpty) {
          context.push('/anime/${n.animeId}');
        } else if (n.actorUsername != null && n.actorUsername!.isNotEmpty) {
          context.push('/profile/${n.actorUsername}');
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isUnread ? AppColors.surfaceElevated : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: Border.all(
            color: n.isUnread
                ? AppColors.primary.withAlpha(100)
                : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: n.isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (n.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.body,
                    style: TextStyle(
                      color: n.isUnread
                          ? Colors.white70
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
                      friend.username.isNotEmpty
                          ? friend.username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: friend.isOnline
                          ? AppColors.successGreen
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceDark,
                        width: 2,
                      ),
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
                    style: AppTypography.titleSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    friend.activityText != null
                        ? 'İzliyor: ${friend.activityText}'
                        : (friend.isOnline ? 'Çevrimiçi' : 'Çevrimdışı'),
                    style: AppTypography.caption.copyWith(
                      color: friend.activityText != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
