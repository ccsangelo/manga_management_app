import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth_state.dart';
import 'package:manga_recommendation_app/bloc/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/pages/home_page.dart';
import 'package:manga_recommendation_app/pages/login_page.dart';
import 'package:manga_recommendation_app/pages/manga_info.dart';
import 'package:manga_recommendation_app/pages/paginated_list_page.dart';
import 'package:manga_recommendation_app/pages/reading_status_page.dart';
import 'package:manga_recommendation_app/pages/register_page.dart';
import 'package:manga_recommendation_app/pages/results_page.dart';
import 'package:manga_recommendation_app/pages/search_page.dart';
import 'package:manga_recommendation_app/pages/shell_page.dart';
import 'package:manga_recommendation_app/pages/user_page.dart';
import 'package:manga_recommendation_app/pages/verification_page.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

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
                builder: (context, _) => BlocProvider(
                  create: (_) => HomeCubit(
                    mangaService: context.read<MangaService>(),
                  )..load(),
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
          return BlocProvider(
            create: (_) => SearchBloc(
              mangaService: context.read<MangaService>(),
            )..add(SearchRequested(keywords, nsfwEnabled: nsfwEnabled)),
            child: ResultsPage(keywords: keywords, nsfwEnabled: nsfwEnabled),
          );
        },
      ),

      // Paginated list pages
      GoRoute(
        path: '/latest-updates',
        builder: (context, _) => BlocProvider(
          create: (_) => PaginatedListCubit(
            fetcher: context.read<MangaService>().getLatestUpdatesPaginated,
          )..loadFirstPage(),
          child: const PaginatedListPage(),
        ),
      ),
    ],
  );
}
