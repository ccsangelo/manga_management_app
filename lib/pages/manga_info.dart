import 'package:flutter/material.dart';
import 'package:manga_recommendation_app/models/manga.dart';

// Detail page for displaying a single manga's full info
class RandomPage extends StatelessWidget {
  final Manga manga;

  const RandomPage({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(manga.title, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Center(
                child: manga.imageUrl != null
                    ? Image.network(
                        manga.imageUrl!,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                manga.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Score
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${manga.score}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tag sections
              if (manga.genres.isNotEmpty)
                _buildTagSection('Genres', manga.genres),
              if (manga.themes.isNotEmpty)
                _buildTagSection('Themes', manga.themes),
              if (manga.demographics.isNotEmpty)
                _buildTagSection('Demographics', manga.demographics),
              if (manga.magazines.isNotEmpty)
                _buildTagSection('Magazines', manga.magazines),

              // Synopsis
              if (manga.synopsis.isNotEmpty) ...[
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
                  manga.synopsis,
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

  // Placeholder for missing cover images
  Widget _placeholderImage() {
    return Container(
      height: 300,
      color: Colors.grey[800],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  // Builds a labeled section with tag chips
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
                .map((tag) => Container(
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
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
