import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/features/auth/presentation/views/login_screen.dart';
import 'package:calium_stream/features/auth/presentation/views/register_screen.dart';
import 'package:calium_stream/features/home/presentation/views/home_screen.dart';
import 'package:calium_stream/features/explore/presentation/views/explore_screen.dart';
import 'package:calium_stream/features/explore/presentation/views/top_anime_screen.dart';
import 'package:calium_stream/features/explore/presentation/views/tr_dub_catalog_screen.dart';
import 'package:calium_stream/features/anime_details/presentation/views/anime_detail_screen.dart';
import 'package:calium_stream/features/player/presentation/views/anime_player_view.dart';
import 'package:calium_stream/features/search/presentation/views/search_screen.dart';
import 'package:calium_stream/features/library/presentation/views/library_screen.dart';
import 'package:calium_stream/features/calendar/presentation/views/calendar_screen.dart';
import 'package:calium_stream/features/user_lists/presentation/views/user_lists_screen.dart';
import 'package:calium_stream/features/user_lists/presentation/views/list_detail_screen.dart';
import 'package:calium_stream/features/settings/presentation/views/settings_screen.dart';
import 'package:calium_stream/features/downloads/presentation/views/downloads_screen.dart';
import 'package:calium_stream/features/profile/presentation/views/profile_screen.dart';
import 'package:calium_stream/features/social/presentation/views/social_screen.dart';

class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryGlow,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.explore_rounded, color: AppColors.primary),
            label: 'Keşfet',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
            label: 'Ara',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'Sosyal',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.video_library_rounded, color: AppColors.primary),
            label: 'Kitaplık',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
  static final _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'explore');
  static final _shellNavigatorSearchKey = GlobalKey<NavigatorState>(debugLabel: 'search');
  static final _shellNavigatorSocialKey = GlobalKey<NavigatorState>(debugLabel: 'social');
  static final _shellNavigatorLibraryKey = GlobalKey<NavigatorState>(debugLabel: 'library');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 0: Home Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // 1: Explore Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),

          // 2: Search Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearchKey,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),

          // 3: Social Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSocialKey,
            routes: [
              GoRoute(
                path: '/social',
                builder: (context, state) => const SocialScreen(),
              ),
            ],
          ),

          // 4: Library Branch
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLibraryKey,
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),

      // Anime Detail (direct route)
      GoRoute(
        path: '/anime/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final animeId = state.pathParameters['id']!;
          return AnimeDetailScreen(animeId: animeId);
        },
      ),

      // Player (full screen, landscape)
      GoRoute(
        path: '/watch/:animeId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final animeId = state.pathParameters['animeId'] ?? '';
          final animeTitle = state.uri.queryParameters['title'] ?? 'Anime';
          final episodeTitle = state.uri.queryParameters['episode'] ?? 'Bölüm 1';
          final episodeId = state.uri.queryParameters['episodeId'] ??
              state.uri.queryParameters['epId'] ??
              '';
          final season = int.tryParse(state.uri.queryParameters['s'] ?? '1') ?? 1;
          final episode = int.tryParse(state.uri.queryParameters['ep'] ?? '1') ?? 1;
          final streamUrl = state.uri.queryParameters['url'] ?? '';
          final posterUrl = state.uri.queryParameters['poster'] ?? '';

          return AnimePlayerView(
            animeId: animeId,
            animeTitle: animeTitle,
            episodeTitle: episodeTitle,
            episodeId: episodeId,
            seasonNumber: season,
            episodeNumber: episode,
            streamUrl: streamUrl,
            posterUrl: posterUrl,
          );
        },
      ),

      // Weekly Airing Calendar
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CalendarScreen(),
      ),

      // User Lists
      GoRoute(
        path: '/lists',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserListsScreen(),
      ),
      GoRoute(
        path: '/lists/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final listId = state.pathParameters['id']!;
          return ListDetailScreen(listId: listId);
        },
      ),

      // Settings & Profile Editor
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Top 100 Leaderboard
      GoRoute(
        path: '/top-anime',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TopAnimeScreen(),
      ),

      // Turkish Dubbed Catalog
      GoRoute(
        path: '/tr-dub',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TrDubCatalogScreen(),
      ),

      // Downloads Manager
      GoRoute(
        path: '/downloads',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadsScreen(),
      ),

      // Profile & User View
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:username',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final username = state.pathParameters['username'];
          return ProfileScreen(username: username);
        },
      ),
    ],
  );
}

