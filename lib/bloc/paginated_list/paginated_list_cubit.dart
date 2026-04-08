import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_state.dart';
import 'package:manga_recommendation_app/models/search_result/manga_search_result.dart';

typedef PageFetcher = Future<Either<String, MangaSearchResult>> Function({int page});

// Generic cubit for paginated manga lists
class PaginatedListCubit extends Cubit<PaginatedListState> {
  final PageFetcher _fetcher;

  PaginatedListCubit({required PageFetcher fetcher})
      : _fetcher = fetcher,
        super(const PaginatedListState());

  Future<void> loadFirstPage() async {
    emit(state.copyWith(status: PaginatedStatus.loading));
    final result = await _fetcher(page: 1);
    result.fold(
      (error) => emit(state.copyWith(
        status: PaginatedStatus.error,
        error: error,
      )),
      (data) => emit(state.copyWith(
        status: PaginatedStatus.loaded,
        manga: data.results,
        currentPage: 1,
        hasNextPage: data.hasNextPage,
      )),
    );
  }

  Future<void> loadNextPage() async {
    if (!state.hasNextPage || state.status == PaginatedStatus.loadingMore) return;

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(status: PaginatedStatus.loadingMore));
    final result = await _fetcher(page: nextPage);
    result.fold(
      (error) => emit(state.copyWith(
        status: PaginatedStatus.loaded,
        error: error,
      )),
      (data) => emit(state.copyWith(
        status: PaginatedStatus.loaded,
        manga: [...state.manga, ...data.results],
        currentPage: nextPage,
        hasNextPage: data.hasNextPage,
      )),
    );
  }
}
