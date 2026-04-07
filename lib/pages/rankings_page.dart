import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list_state.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    final service = context.read<MangaService>();
    _cubits = _tabs.map((tab) {
      return PaginatedListCubit(
        fetcher: ({int page = 1}) => service.getTopMangaPaginated(
          type: tab.type,
          filter: tab.filter,
          page: page,
        ),
      )..loadFirstPage();
    }).toList();
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
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.deepPurple,
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

class _RankingTabView extends StatelessWidget {
  const _RankingTabView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginatedListCubit, PaginatedListState>(
      builder: (context, state) {
        if (state.status == PaginatedStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
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
                      style: TextStyle(color: Colors.deepPurple)),
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
              context.read<PaginatedListCubit>().loadNextPage();
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
                        color: Colors.deepPurple, strokeWidth: 2),
                  ),
                );
              }
              return _GridMangaCard(manga: state.manga[index]);
            },
          ),
        );
      },
    );
  }
}

class _GridMangaCard extends StatelessWidget {
  final Manga manga;
  const _GridMangaCard({required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/manga', extra: manga),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: manga.imageUrl != null
                  ? Image.network(
                      manga.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            manga.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: const Center(
        child: Icon(Icons.menu_book, color: Colors.grey, size: 28),
      ),
    );
  }
}
