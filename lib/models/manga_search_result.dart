import 'package:manga_recommendation_app/models/manga.dart';

class MangaSearchResult {
  final List<Manga> results;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const MangaSearchResult({
    required this.results,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });
}
