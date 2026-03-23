import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth_state.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/pages/home_page.dart';
import 'package:manga_recommendation_app/pages/login_page.dart';
import 'package:manga_recommendation_app/pages/manga_info.dart';
import 'package:manga_recommendation_app/pages/results_page.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

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

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final isAuthenticated = authBloc.state is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomePage(),
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
      GoRoute(
        path: '/manga',
        builder: (_, state) => MangaPage(manga: state.extra as Manga),
      ),
    ],
  );
}
