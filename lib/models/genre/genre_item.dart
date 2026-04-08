// Genre/theme/demographic/magazine entry from Jikan
class GenreItem {
  final int malId;
  final String name;
  final int count;

  const GenreItem({required this.malId, required this.name, required this.count});

  factory GenreItem.fromJson(Map<String, dynamic> json) => GenreItem(
        malId: json['mal_id'] as int,
        name: json['name'] as String,
        count: json['count'] as int? ?? 0,
      );
}
