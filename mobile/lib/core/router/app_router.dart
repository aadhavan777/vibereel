import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/create/presentation/views/create_view.dart';
import '../../features/creator_forum/presentation/views/forum_view.dart';
import '../../features/discover/presentation/views/discover_view.dart';
import '../../features/feed/presentation/views/feed_view.dart';
import '../../features/notifications/presentation/views/notifications_view.dart';
import '../../features/onboarding/presentation/views/onboarding_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/search/presentation/views/search_view.dart';
import '../../features/settings/presentation/views/settings_view.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashView(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchView(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsView(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const FeedView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/create',
                builder: (context, state) => const CreateView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/forum',
                builder: (context, state) => const ForumView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
