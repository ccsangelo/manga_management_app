import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_state.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';
import 'package:manga_recommendation_app/widgets/manga_card.dart';

// Rankings tabs: type param for /top/manga, filter param for bypopularity
const _tabs = <({String label, String? type, String? filter})>[
  (label: 'All Manga', type: null, filter: null),
  (label: 'Top Manga', type: 'manga', filter: null),
  (label: 'Top One-shots', type: 'oneshot', filter: null),
  (label: 'Top Doujinshi', type: 'doujin', filter: null),
  (label: 'Top Light Novels', type: 'lightnovel', filter: null),
  (label: 'Top Novels', type: 'novel', filter: null),
  (label: 'Top Manhwa', type: 'manhwa', filter: null),
  (label: 'Top Manhua', type: 'manhua', filter: null),
  (label: 'Most Popular', type: null, filter: 'bypopularity'),
];

// Paginated rankings page with 9 category tabs
class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<PaginatedListCubit> _cubits;
  final Set<int> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    final service = context.read<MangaService>();
    final nsfw = UserPreferencesService.instance.isNsfwEnabled(
      context.read<AuthBloc>().state,
    );
    _cubits = _tabs.map((tab) {
      return PaginatedListCubit(
        fetcher: ({int page = 1}) => service.getTopMangaPaginated(
          type: tab.type,
          filter: tab.filter,
          page: page,
          nsfwEnabled: nsfw,
        ),
      );
    }).toList();

    // Only load the first tab immediately
    _loadTab(0);

    // Load tabs lazily as user swipes to them
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
  }

  void _loadTab(int index) {
    if (_loadedTabs.add(index)) {
      _cubits[index].loadFirstPage();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final cubit in _cubits) {
      cubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _cubits
            .map((cubit) => BlocProvider.value(
                  value: cubit,
                  child: const _RankingTabView(),
                ))
            .toList(),
      ),
    );
  }
}

class _RankingTabView extends StatefulWidget {
  const _RankingTabView();

  @override
  State<_RankingTabView> createState() => _RankingTabViewState();
}

class _RankingTabViewState extends State<_RankingTabView> {
  Timer? _scrollDebounce;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedListCubit, PaginatedListState>(
      builder: (context, state) {
        if (state.status == PaginatedStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        if (state.status == PaginatedStatus.error && state.manga.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.error ?? 'Something went wrong.',
                  style: TextStyle(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      context.read<PaginatedListCubit>().loadFirstPage(),
                  child: const Text('Retry',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ],
            ),
          );
        }

        if (state.manga.isEmpty) {
          return const Center(
            child:
                Text('No manga found.', style: TextStyle(color: Colors.grey)),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
              _scrollDebounce?.cancel();
              _scrollDebounce = Timer(
                const Duration(milliseconds: 300),
                () => context.read<PaginatedListCubit>().loadNextPage(),
              );
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.manga.length +
                (state.status == PaginatedStatus.loadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.manga.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                  ),
                );
              }
              return GridMangaCard(manga: state.manga[index]);
            },
          ),
        );
      },
    );
  }
}

