import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/models/anime/anime.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';

// Anime tabs: filter param for /top/anime
const _tabs = <({String label, String? filter})>[
  (label: 'Explore', filter: null),
  (label: 'Airing Now', filter: 'airing'),
  (label: 'Upcoming Anime', filter: 'upcoming'),
];

// Paginated anime page with 3 category tabs
class AdaptedAnimePage extends StatefulWidget {
  const AdaptedAnimePage({super.key});

  @override
  State<AdaptedAnimePage> createState() => _AdaptedAnimePageState();
}

class _AdaptedAnimePageState extends State<AdaptedAnimePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<_AnimeTabState> _tabStates;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabStates = _tabs
        .map((tab) => _AnimeTabState(filter: tab.filter))
        .toList();
    // Load the first tab immediately
    _loadTab(0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
  }

  void _loadTab(int index) {
    if (_tabStates[index].anime.isEmpty &&
        !_tabStates[index].isLoading &&
        _tabStates[index].error == null) {
      _fetchPage(index);
    }
  }

  Future<void> _fetchPage(int index) async {
    final tabState = _tabStates[index];
    if (tabState.isLoading || !tabState.hasNextPage && tabState.anime.isNotEmpty) return;

    setState(() => tabState.isLoading = true);

    final result = await context.read<MangaService>().getTopAnimePaginated(
          filter: tabState.filter,
          page: tabState.currentPage,
        );

    if (!mounted) return;
    setState(() {
      tabState.isLoading = false;
      result.fold(
        (error) => tabState.error = error,
        (data) {
          tabState.anime.addAll(data.results);
          tabState.currentPage++;
          tabState.hasNextPage = data.hasNextPage;
        },
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (i) {
          return _AnimeTabView(
            tabState: _tabStates[i],
            onLoadMore: () => _fetchPage(i),
          );
        }),
      ),
    );
  }
}

// Mutable state per tab
class _AnimeTabState {
  final String? filter;
  List<Anime> anime = [];
  int currentPage = 1;
  bool hasNextPage = true;
  bool isLoading = false;
  String? error;

  _AnimeTabState({required this.filter});
}

class _AnimeTabView extends StatelessWidget {
  final _AnimeTabState tabState;
  final VoidCallback onLoadMore;

  const _AnimeTabView({required this.tabState, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    if (tabState.isLoading && tabState.anime.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (tabState.error != null && tabState.anime.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tabState.error!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLoadMore,
              child: const Text('Retry',
                  style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        ),
      );
    }

    if (tabState.anime.isEmpty) {
      return const Center(
        child: Text('No anime found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
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
        itemCount: tabState.anime.length +
            (tabState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tabState.anime.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: Colors.deepPurple, strokeWidth: 2),
              ),
            );
          }
          return _GridAnimeCard(anime: tabState.anime[index]);
        },
      ),
    );
  }
}

class _GridAnimeCard extends StatelessWidget {
  final Anime anime;
  const _GridAnimeCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                anime.imageUrl != null
                    ? Image.network(
                        anime.imageUrl!,
                        width: double.infinity,
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
                if (anime.score > 0)
                  Positioned(
                    bottom: 4,
                    right: 6,
                    child: Text(
                      anime.score.toStringAsFixed(1),
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
        const SizedBox(height: 4),
        Text(
          anime.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(Icons.movie, color: Colors.grey, size: 28),
      ),
    );
  }
}
