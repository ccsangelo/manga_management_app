import 'package:flutter/material.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';
import 'package:manga_recommendation_app/widgets/manga_card.dart';

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
        backgroundColor: AppColors.surface,
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
                  GridMangaCard(manga: _manga[index], onReturn: _refresh),
            ),
    );
  }
}


