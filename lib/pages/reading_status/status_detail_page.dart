import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';

// Scrollable grid of all manga with a specific reading status
class StatusDetailPage extends StatefulWidget {
  final String status;
  const StatusDetailPage({super.key, required this.status});

  @override
  State<StatusDetailPage> createState() => _StatusDetailPageState();
}

class _StatusDetailPageState extends State<StatusDetailPage> {
  List<Manga> _manga = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _manga = MangaStatusService.instance.getMangaByStatus(widget.status);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: Text(widget.status),
      ),
      body: _manga.isEmpty
          ? const Center(
              child: Text('No manga found.',
                  style: TextStyle(color: Colors.grey)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _manga.length,
              itemBuilder: (context, index) =>
                  _GridMangaCard(manga: _manga[index], onReturn: _refresh),
            ),
    );
  }
}

class _GridMangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onReturn;
  const _GridMangaCard({required this.manga, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/manga', extra: manga);
        onReturn();
      },
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
