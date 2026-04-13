import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_state.dart';
import 'package:manga_recommendation_app/bloc/home/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/search/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_event.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/pages/rankings/adapted_anime_page.dart';
import 'package:manga_recommendation_app/pages/home/home_page.dart';
import 'package:manga_recommendation_app/pages/auth/login_page.dart';
import 'package:manga_recommendation_app/pages/manga/manga_info.dart';
import 'package:manga_recommendation_app/pages/rankings/paginated_list_page.dart';
import 'package:manga_recommendation_app/pages/rankings/rankings_page.dart';
import 'package:manga_recommendation_app/pages/reading_status/reading_status_page.dart';
import 'package:manga_recommendation_app/pages/auth/register_page.dart';
import 'package:manga_recommendation_app/pages/search/results_page.dart';
import 'package:manga_recommendation_app/pages/search/search_page.dart';
import 'package:manga_recommendation_app/pages/shell/shell_page.dart';
import 'package:manga_recommendation_app/pages/reading_status/status_detail_page.dart';
import 'package:manga_recommendation_app/pages/auth/user_page.dart';
import 'package:manga_recommendation_app/pages/auth/verification_page.dart';
import 'package:manga_recommendation_app/pages/onboarding/onboarding_page.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';

// Notifier that triggers GoRouter refresh on stream events
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// App router with bottom nav shell and auth-based redirects
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final isAuthenticated = authBloc.state is AuthAuthenticated;
      final path = state.matchedLocation;
      final authRoutes = ['/login', '/register', '/verify'];

      // First run: show onboarding before anything else
      if (!UserPreferencesService.instance.hasSeenOnboarding &&
          path != '/onboarding') {
        return '/onboarding';
      }

      // If logged in and trying to visit auth pages, go home
      if (isAuthenticated && authRoutes.contains(path)) return '/';
      return null;
    },
    routes: [
      // Bottom navigation shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellPage(navigationShell: navigationShell),
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, _) => BlocProvider.value(
                  value: context.read<HomeCubit>(),
                  child: const HomePage(),
                ),
              ),
            ],
          ),
          // Search tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (_, _) => const SearchPage(),
              ),
            ],
          ),
          // Reading Status tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reading-status',
                builder: (_, _) => const ReadingStatusPage(),
              ),
            ],
          ),
          // User tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/user',
                builder: (_, _) => const UserPage(),
              ),
            ],
          ),
        ],
      ),

      // Auth pages
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, _) => const VerificationPage(),
      ),

      // Detail & results pages (pushed on top of shell)
      GoRoute(
        path: '/manga',
        builder: (_, state) => MangaPage(manga: state.extra as Manga),
      ),
      GoRoute(
        path: '/results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final keywords = extra['keywords'] as String;
          final nsfwEnabled = extra['nsfwEnabled'] as bool? ?? false;
          final orMode = extra['orMode'] as bool? ?? false;
          return BlocProvider(
            create: (_) => SearchBloc(
              mangaService: context.read<MangaService>(),
            )..add(SearchRequested(keywords,
                nsfwEnabled: nsfwEnabled, orMode: orMode)),
            child: ResultsPage(
                keywords: keywords,
                nsfwEnabled: nsfwEnabled,
                orMode: orMode),
          );
        },
      ),

      // Paginated list pages
      GoRoute(
        path: '/latest-updates',
        builder: (context, _) {
          final nsfw = UserPreferencesService.instance.isNsfwEnabled(
            context.read<AuthBloc>().state,
          );
          return BlocProvider(
            create: (_) => PaginatedListCubit(
              fetcher: ({int page = 1}) =>
                  context.read<MangaService>().getLatestUpdatesPaginated(
                    page: page,
                    nsfwEnabled: nsfw,
                  ),
            )..loadFirstPage(),
            child: const PaginatedListPage(),
          );
        },
      ),

      // Adapted to Anime page (3 tabs)
      GoRoute(
        path: '/adapted-anime',
        builder: (_, _) => const AdaptedAnimePage(),
      ),

      // Rankings page (9 tabs)
      GoRoute(
        path: '/rankings',
        builder: (_, _) => const RankingsPage(),
      ),

      // Status detail page (all manga with a given status)
      GoRoute(
        path: '/reading-status/detail',
        builder: (_, state) =>
            StatusDetailPage(status: state.extra as String),
      ),

      // Onboarding (shown once on first launch)
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const OnboardingPage(),
      ),
    ],
  );
}
