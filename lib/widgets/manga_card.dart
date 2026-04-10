import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/widgets/card_components.dart';

// Horizontal scrolling manga card (130×170) used in home, search preview, reading status
class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onReturn;

  const MangaCard({super.key, required this.manga, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/manga', extra: manga);
        onReturn?.call();
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
                    _buildImage(manga.imageUrl, height: 170, width: 130),
                    const ScoreGradient(),
                    if (manga.score > 0) ScoreBadge(score: manga.score),
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
}

// Grid manga card (expanding height) used in results, rankings, paginated lists, status detail
class GridMangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onReturn;

  const GridMangaCard({super.key, required this.manga, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/manga', extra: manga);
        onReturn?.call();
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
                  _buildImage(manga.imageUrl),
                  const ScoreGradient(),
                  if (manga.score > 0) ScoreBadge(score: manga.score),
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
}

// Shared image builder with CachedNetworkImage
Widget _buildImage(String? imageUrl, {double? height, double? width}) {
  if (imageUrl == null) return _MangaPlaceholder(height: height, width: width);
  return CachedNetworkImage(
    imageUrl: imageUrl,
    height: height,
    width: width ?? double.infinity,
    fit: BoxFit.cover,
    placeholder: (_, _) => _MangaPlaceholder(height: height, width: width),
    errorWidget: (_, _, _) => _MangaPlaceholder(height: height, width: width),
  );
}

class _MangaPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;

  const _MangaPlaceholder({this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.menu_book, color: Colors.grey, size: 28),
      ),
    );
  }
}


