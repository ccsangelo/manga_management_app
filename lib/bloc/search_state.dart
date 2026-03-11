import 'package:manga_recommendation_app/models/manga.dart';

// Search state definitions
abstract class SearchState {}

class SearchInitial extends SearchState {}

// Search in progress
class SearchLoading extends SearchState {}

// Search completed with results and pagination info
class SearchSuccess extends SearchState {
  final List<Manga> results;
  final String keywords;
  final int currentPage;
  final int lastPage;

  SearchSuccess(
    this.results, {
    required this.keywords,
    this.currentPage = 1,
    this.lastPage = 1,
  });
}

// Search failed
class SearchFailure extends SearchState {
  final String message;

  SearchFailure(this.message);
}

// Random manga fetch in progress
class RandomLoading extends SearchState {}

// Random manga fetch succeeded
class RandomSuccess extends SearchState {
  final Manga manga;

  RandomSuccess(this.manga);
}

// Random manga fetch failed
class RandomFailure extends SearchState {
  final String message;

  RandomFailure(this.message);
}

