// Minimal anime model for Adapted to Anime pages
class Anime {
  final int malId;
  final String title;
  final String? imageUrl;
  final double score;
  final String synopsis;

  const Anime({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.score = 0.0,
    this.synopsis = '',
  });

  factory Anime.fromJson(Map<String, dynamic> json) => Anime(
        malId: json['mal_id'] as int,
        title: json['title'] as String? ?? '',
        imageUrl: (json['images'] as Map<String, dynamic>?)?['jpg']
            ?['image_url'] as String?,
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        synopsis: json['synopsis'] as String? ?? '',
      );
}

class AnimeSearchResult {
  final List<Anime> results;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const AnimeSearchResult({
    required this.results,
    this.currentPage = 1,
    this.lastPage = 1,
    this.hasNextPage = false,
  });
}
