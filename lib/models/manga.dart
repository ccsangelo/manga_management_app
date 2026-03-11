// Manga data model parsed from Jikan API
class Manga {
  final int malId;
  final String title;
  final List<String> genres;
  final List<String> themes;
  final List<String> demographics;
  final List<String> magazines;
  final String synopsis;
  final String? imageUrl;
  final double score;

  const Manga({
    required this.malId,
    required this.title,
    required this.genres,
    required this.themes,
    required this.demographics,
    required this.magazines,
    required this.synopsis,
    this.imageUrl,
    this.score = 0.0,
  });

  // Extracts lowercase name strings from a JSON array field
  static List<String> _extractNames(Map<String, dynamic> json, String key) {
    return (json[key] as List<dynamic>? ?? [])
        .map((item) => (item['name'] as String).toLowerCase())
        .toList();
  }

  factory Manga.fromJson(Map<String, dynamic> json) {
    // Parse image URL from nested images.jpg structure
    String? imageUrl;
    final images = json['images'] as Map<String, dynamic>?;
    if (images != null) {
      imageUrl =
          (images['jpg'] as Map<String, dynamic>?)?['image_url'] as String?;
    }

    return Manga(
      malId: json['mal_id'] as int,
      title: json['title'] as String,
      genres: _extractNames(json, 'genres'),
      themes: _extractNames(json, 'themes'),
      demographics: _extractNames(json, 'demographics'),
      magazines: _extractNames(json, 'serializations'),
      synopsis: (json['synopsis'] as String?) ?? '',
      imageUrl: imageUrl,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
