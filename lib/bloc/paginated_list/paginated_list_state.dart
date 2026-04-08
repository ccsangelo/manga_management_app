import 'package:manga_recommendation_app/models/manga/manga.dart';

// Paginated list page states
class PaginatedListState {
  final PaginatedStatus status;
  final List<Manga> manga;
  final int currentPage;
  final bool hasNextPage;
  final String? error;

  const PaginatedListState({
    this.status = PaginatedStatus.loading,
    this.manga = const [],
    this.currentPage = 1,
    this.hasNextPage = false,
    this.error,
  });

  PaginatedListState copyWith({
    PaginatedStatus? status,
    List<Manga>? manga,
    int? currentPage,
    bool? hasNextPage,
    String? error,
  }) {
    return PaginatedListState(
      status: status ?? this.status,
      manga: manga ?? this.manga,
      currentPage: currentPage ?? this.currentPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      error: error ?? this.error,
    );
  }
}

enum PaginatedStatus { loading, loaded, loadingMore, error }
