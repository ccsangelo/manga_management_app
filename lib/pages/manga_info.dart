import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/services/manga_status_service.dart';

// Manga detail page with status picker, tags, and synopsis
class MangaPage extends StatefulWidget {
  final Manga manga;

  const MangaPage({super.key, required this.manga});

  @override
  State<MangaPage> createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = MangaStatusService.instance.getStatus(widget.manga.malId);
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Set Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A)),
          ...MangaStatusService.statusOptions.map(
            (status) => ListTile(
              title: Text(status, style: const TextStyle(color: Colors.white)),
              trailing: _status == status
                  ? const Icon(Icons.check, color: Colors.deepPurple)
                  : null,
              onTap: () {
                setState(() {
                  _status = status;
                  MangaStatusService.instance
                      .setStatus(widget.manga.malId, status);
                });
                Navigator.pop(context);
              },
            ),
          ),
          if (_status != null)
            ListTile(
              title: const Text('Remove Status',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                setState(() {
                  _status = null;
                  MangaStatusService.instance
                      .setStatus(widget.manga.malId, null);
                });
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.manga.title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _status != null ? Icons.bookmark : Icons.bookmark_border,
              color: _status != null ? Colors.deepPurple : Colors.white,
            ),
            tooltip: 'Set Status',
            onPressed: _showStatusPicker,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: widget.manga.imageUrl != null
                    ? Image.network(
                        widget.manga.imageUrl!,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(height: 24),

              Text(
                widget.manga.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              if (_status != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.deepPurple.withAlpha(128), width: 1),
                  ),
                  child: Text(
                    _status!,
                    style: const TextStyle(
                        color: Colors.deepPurple, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.manga.score}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (widget.manga.genres.isNotEmpty)
                _buildTagSection('Genres', widget.manga.genres),
              if (widget.manga.themes.isNotEmpty)
                _buildTagSection('Themes', widget.manga.themes),
              if (widget.manga.demographics.isNotEmpty)
                _buildTagSection('Demographics', widget.manga.demographics),
              if (widget.manga.magazines.isNotEmpty)
                _buildTagSection('Magazines', widget.manga.magazines),

              if (widget.manga.synopsis.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Synopsis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.manga.synopsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 300,
      color: Colors.grey[800],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget _buildTagSection(String label, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((tag) => GestureDetector(
                      onTap: () => context.push('/results', extra: {
                        'keywords': tag,
                        'nsfwEnabled': false,
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
