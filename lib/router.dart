import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/connect/connect_page.dart';
import 'pages/detail/detail_page.dart';
import 'pages/downloads/downloads_page.dart';
import 'pages/favorites/favorites_page.dart';
import 'pages/home/home_page.dart';
import 'pages/libraries/libraries_page.dart';
import 'pages/library/library_page.dart';
import 'pages/login/login_page.dart';
import 'pages/player/player_page.dart';
import 'pages/profiles/profiles_page.dart';
import 'pages/search/search_page.dart';
import 'pages/settings/settings_page.dart';
import 'providers/session_provider.dart';
import 'widgets/app_shell.dart';
import 'widgets/title_bar.dart';
import 'widgets/platform.dart';
import 'widgets/window_actions.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final bootstrapped = ref.watch(bootstrappedProvider);
  final pendingServer = ref.watch(pendingServerProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final path = state.uri.path;
      if (!bootstrapped) {
        return path == '/splash' ? null : '/splash';
      }
      const authRoutes = {'/connect', '/login', '/profiles', '/splash'};
      final signedIn = session != null;
      if (!signedIn) {
        if (path == '/login' && pendingServer == null) {
          return '/connect';
        }
        return authRoutes.contains(path) ? null : '/profiles';
      }
      if (authRoutes.contains(path)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/connect',
        builder: (_, _) => const ConnectPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/profiles',
        builder: (_, _) => const ProfilesPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, _) => const HomePage(),
          ),
          GoRoute(
            path: '/libraries',
            builder: (_, _) => const LibrariesPage(),
          ),
          GoRoute(
            path: '/library/:id',
            builder: (_, state) => LibraryPage(
              libraryId: state.pathParameters['id']!,
              libraryName: state.uri.queryParameters['name'],
            ),
          ),
          GoRoute(
            path: '/search',
            builder: (_, _) => const SearchPage(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (_, _) => const FavoritesPage(),
          ),
          GoRoute(
            path: '/downloads',
            builder: (_, _) => const DownloadsPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsPage(),
          ),
          GoRoute(
            path: '/item/:id',
            builder: (_, state) =>
                DetailPage(itemId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/play',
        builder: (_, _) => const PlayerPage(),
      ),
    ],
  );
});

WindowActions? defaultWindowActions() =>
    isDesktopPlatform ? const WindowManagerActions() : null;
