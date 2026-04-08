import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';

// Generic paginated manga list page
class PaginatedListPage extends StatelessWidget {
  const PaginatedListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PaginatedListCubit, PaginatedListState>(
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
              child: Text('No manga found.', style: TextStyle(color: Colors.grey)),
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
