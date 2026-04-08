import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';

// Reading list page grouped by status sections
class ReadingStatusPage extends StatefulWidget {
  const ReadingStatusPage({super.key});

  @override
  State<ReadingStatusPage> createState() => _ReadingStatusPageState();
}

class _ReadingStatusPageState extends State<ReadingStatusPage> {
  Map<String, List<Manga>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _refresh();
    MangaStatusService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    MangaStatusService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _grouped = MangaStatusService.instance.getAllGroupedByStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which sections to show, preserving canonical order
    final sections = MangaStatusService.statusOptions
        .where((s) => _grouped.containsKey(s) && _grouped[s]!.isNotEmpty)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: sections.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border, color: Colors.grey, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Your reading list is empty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Set a status on any manga to start building your list.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final status = sections[index];
                  final manga = _grouped[status]!;
                  return _StatusSection(
                    status: status,
                    manga: manga,
                    onReturn: _refresh,
                  );
                },
              ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final String status;
  final List<Manga> manga;
  final VoidCallback onReturn;

  const _StatusSection({
    required this.status,
    required this.manga,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final preview = manga.take(10).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (manga.length > 10)
                IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: Colors.grey, size: 20),
                  onPressed: () async {
                    await context.push('/reading-status/detail',
                        extra: status);
                    onReturn();
                  },
                ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _MangaCard(
              manga: preview[index],
              onReturn: onReturn,
            ),
          ),
        ),
      ],
    );
  }
}

class _MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onReturn;
  const _MangaCard({required this.manga, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/manga', extra: manga);
        onReturn();
      },
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
