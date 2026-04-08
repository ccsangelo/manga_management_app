import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_state.dart';
import 'package:manga_recommendation_app/bloc/home/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/home/home_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';

// Landing page with Popular Now, Latest Updates, Recommended, and Random
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _lastNsfw = false;

  bool _currentNsfw() =>
      UserPreferencesService.instance.isNsfwEnabled(
        context.read<AuthBloc>().state,
      );

  void _scheduleReloadIfNeeded() {
    final nsfw = _currentNsfw();
    if (nsfw != _lastNsfw) {
      _lastNsfw = nsfw;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeCubit>().load(nsfwEnabled: nsfw);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isLoggedIn = authState is AuthAuthenticated;

    return ListenableBuilder(
      listenable: UserPreferencesService.instance,
      builder: (context, _) {
        _scheduleReloadIfNeeded();

        return Scaffold(
          body: SafeArea(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return RefreshIndicator(
                  color: Colors.deepPurple,
                  onRefresh: () => context.read<HomeCubit>().load(nsfwEnabled: _currentNsfw()),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Popular Now
                  const _SectionHeader(title: 'Popular Now'),
                  _MangaSection(
                    status: state.popularStatus,
                    manga: state.popularManga,
                    error: state.popularError,
                  ),
                  const SizedBox(height: 24),

                  // Latest Updates — arrow navigates to paginated page
                  _SectionHeader(
                    title: 'Latest Updates',
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                      onPressed: () => context.push('/latest-updates'),
                    ),
                  ),
                  _MangaSection(
                    status: state.latestStatus,
                    manga: state.latestManga,
                    error: state.latestError,
                  ),
                  const SizedBox(height: 24),

                  // Recommended — only shown when logged in
                  if (isLoggedIn) ...[
                    const _SectionHeader(title: 'Recommended'),
                    _MangaSection(
                      status: state.recommendedStatus,
                      manga: state.recommendedManga,
                      error: state.recommendedError,
                      emptyWidget: state.recommendedHasHistory
                          ? null
                          : const _RecommendedNotice(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Random — refresh icon reloads random manga
                  _SectionHeader(
                    title: 'Random',
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                      onPressed: () => context.read<HomeCubit>().refreshRandom(nsfwEnabled: _currentNsfw()),
                    ),
                  ),
                  _MangaSection(
                    status: state.randomStatus,
                    manga: state.randomManga,
                    error: state.randomError,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _RecommendedNotice extends StatelessWidget {
  const _RecommendedNotice();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, color: Colors.grey, size: 40),
            SizedBox(height: 12),
            Text(
              'Track manga to get personalized recommendations.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MangaSection extends StatelessWidget {
  final HomeStatus status;
  final List<Manga> manga;
  final String? error;
  final Widget? emptyWidget;

  const _MangaSection({
    required this.status,
    required this.manga,
    this.error,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (status == HomeStatus.loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }

    if (status == HomeStatus.error) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? 'Something went wrong.',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<HomeCubit>().load(
                  nsfwEnabled: UserPreferencesService.instance.isNsfwEnabled(
                    context.read<AuthBloc>().state,
                  ),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.deepPurple)),
              ),
            ],
          ),
        ),
      );
    }

    if (manga.isEmpty) {
      return emptyWidget ??
          const SizedBox(
            height: 220,
            child: Center(
              child: Text('No manga found.', style: TextStyle(color: Colors.grey)),
            ),
          );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: manga.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _MangaCard(manga: manga[index]),
      ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  final Manga manga;
  const _MangaCard({required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/manga', extra: manga),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 170,
                width: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    manga.imageUrl != null
                        ? Image.network(
                            manga.imageUrl!,
                            height: 170,
                            width: 130,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : _placeholder(),
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                    if (manga.score > 0)
                      Positioned(
                        bottom: 4,
                        right: 6,
                        child: Text(
                          manga.score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 170,
      width: 130,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.menu_book, color: Colors.grey, size: 32),
    );
  }
}