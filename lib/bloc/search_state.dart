import 'package:manga_recommendation_app/models/manga.dart';

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

  SearchSuccess(
    this.results, {
    required this.keywords,
    this.currentPage = 1,
    this.lastPage = 1,
    this.sortDescending = true,
  });
}

class SearchFailure extends SearchState {
  final String message;

  SearchFailure(this.message);
}

