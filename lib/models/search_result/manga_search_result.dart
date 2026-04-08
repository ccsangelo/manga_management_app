import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';

part 'manga_search_result.freezed.dart';

// Paginated search result model
@freezed
class MangaSearchResult with _$MangaSearchResult {
  const factory MangaSearchResult({
    required List<Manga> results,
    required int currentPage,
    required int lastPage,
    required bool hasNextPage,
  }) = _MangaSearchResult;
}
