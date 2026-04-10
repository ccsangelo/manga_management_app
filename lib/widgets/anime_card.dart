import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/models/anime/anime.dart';
import 'package:manga_recommendation_app/widgets/card_components.dart';

// Horizontal scrolling anime card (130×170) used in search preview
class AnimeCard extends StatelessWidget {
  final Anime anime;

  const AnimeCard({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  _buildAnimeImage(anime.imageUrl, height: 170, width: 130),
                  const ScoreGradient(),
                  if (anime.score > 0) ScoreBadge(score: anime.score),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
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
    );
  }
}

// Grid anime card (expanding height) used in adapted anime page
class GridAnimeCard extends StatelessWidget {
  final Anime anime;

  const GridAnimeCard({super.key, required this.anime});

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
                _buildAnimeImage(anime.imageUrl),
                const ScoreGradient(),
                if (anime.score > 0) ScoreBadge(score: anime.score),
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
}

Widget _buildAnimeImage(String? imageUrl, {double? height, double? width}) {
  if (imageUrl == null) return _AnimePlaceholder(height: height, width: width);
  return CachedNetworkImage(
    imageUrl: imageUrl,
    height: height,
    width: width ?? double.infinity,
    fit: BoxFit.cover,
    placeholder: (_, _) => _AnimePlaceholder(height: height, width: width),
    errorWidget: (_, _, _) => _AnimePlaceholder(height: height, width: width),
  );
}

class _AnimePlaceholder extends StatelessWidget {
  final double? height;
  final double? width;

  const _AnimePlaceholder({this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.movie, color: Colors.grey, size: 28),
      ),
    );
  }
}


