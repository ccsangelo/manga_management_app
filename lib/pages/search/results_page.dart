import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/search/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_event.dart';
import 'package:manga_recommendation_app/bloc/search/search_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';

// Search results with card grid, infinite scroll, and sort toggle
class ResultsPage extends StatefulWidget {
  final String keywords;
  final bool nsfwEnabled;
  final bool orMode;

  const ResultsPage({
    super.key,
    required this.keywords,
    this.nsfwEnabled = false,
    this.orMode = false,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _sortDescending = true;

  void _toggleSort() {
    setState(() => _sortDescending = !_sortDescending);
    final state = context.read<SearchBloc>().state;
    final keywords =
        state is SearchSuccess ? state.keywords : widget.keywords;
    context.read<SearchBloc>().add(
          SearchRequested(
            keywords,
            nsfwEnabled: widget.nsfwEnabled,
            sortDescending: _sortDescending,
            orMode: widget.orMode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _sortDescending
                ? 'Score: High to Low'
                : 'Score: Low to High',
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (state is SearchFailure) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          if (state is! SearchSuccess) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (state.results.isEmpty) {
            return const Center(
              child: Text(
                'No results found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                context.read<SearchBloc>().add(LoadMoreResults());
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
              itemCount: state.results.length +
                  (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.results.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: Colors.deepPurple, strokeWidth: 2),
                    ),
                  );
                }
                return _GridMangaCard(manga: state.results[index]);
              },
            ),
          );
        },
      ),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  manga.imageUrl != null
                      ? Image.network(
                          manga.imageUrl!,
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
