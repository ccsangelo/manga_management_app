import 'package:manga_recommendation_app/models/manga/manga.dart';

// Search states
abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final List<Manga> results;
  final String keywords;
  final int currentPage;
  final int lastPage;
  final bool sortDescending;
  final bool hasNextPage;
  final bool isLoadingMore;
  final bool nsfwEnabled;
  final bool orMode;

  SearchSuccess(
    this.results, {
    required this.keywords,
    this.currentPage = 1,
    this.lastPage = 1,
    this.sortDescending = true,
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.nsfwEnabled = false,
    this.orMode = false,
  });
}

class SearchFailure extends SearchState {
  final String message;

  SearchFailure(this.message);
}

