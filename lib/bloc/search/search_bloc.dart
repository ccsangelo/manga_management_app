import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_event.dart';
import 'package:manga_recommendation_app/bloc/search/search_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';

// Manages manga search with Hive-backed state persistence
class SearchBloc extends HydratedBloc<SearchEvent, SearchState> {
  final MangaService _mangaService;

  SearchBloc({required MangaService mangaService})
      : _mangaService = mangaService,
        super(SearchInitial()) {
    on<SearchRequested>((event, emit) async {
      emit(SearchLoading());
      final result = await _mangaService.searchManga(
        event.keywords,
        page: event.page,
        nsfwEnabled: event.nsfwEnabled,
        sortDescending: event.sortDescending,
        orMode: event.orMode,
      );
      emit(result.fold(
        (error) => SearchFailure(error),
        (data) => SearchSuccess(
          data.results,
          keywords: event.keywords,
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          sortDescending: event.sortDescending,
          hasNextPage: data.hasNextPage,
          nsfwEnabled: event.nsfwEnabled,
          orMode: event.orMode,
        ),
      ));
    });

    on<LoadMoreResults>((event, emit) async {
      final current = state;
      if (current is! SearchSuccess || current.isLoadingMore || !current.hasNextPage) return;

      emit(SearchSuccess(
        current.results,
        keywords: current.keywords,
        currentPage: current.currentPage,
        lastPage: current.lastPage,
        sortDescending: current.sortDescending,
        hasNextPage: current.hasNextPage,
        isLoadingMore: true,
        nsfwEnabled: current.nsfwEnabled,
        orMode: current.orMode,
      ));

      // Respect Jikan rate limit
      await Future.delayed(const Duration(milliseconds: 400));

      final nextPage = current.currentPage + 1;
      final result = await _mangaService.searchManga(
        current.keywords,
        page: nextPage,
        nsfwEnabled: current.nsfwEnabled,
        sortDescending: current.sortDescending,
        orMode: current.orMode,
      );

      emit(result.fold(
        (error) => SearchSuccess(
          current.results,
          keywords: current.keywords,
          currentPage: current.currentPage,
          lastPage: current.lastPage,
          sortDescending: current.sortDescending,
          hasNextPage: current.hasNextPage,
          nsfwEnabled: current.nsfwEnabled,
          orMode: current.orMode,
        ),
        (data) => SearchSuccess(
          [...current.results, ...data.results],
          keywords: current.keywords,
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          sortDescending: current.sortDescending,
          hasNextPage: data.hasNextPage,
          nsfwEnabled: current.nsfwEnabled,
          orMode: current.orMode,
        ),
      ));
    });
  }

  @override
  SearchState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['type'] == 'success') {
        return SearchSuccess(
          (json['results'] as List)
              .map((e) => mangaFromCacheMap(e as Map<String, dynamic>))
              .toList(),
          keywords: json['keywords'] as String,
          currentPage: json['currentPage'] as int,
          lastPage: json['lastPage'] as int,
          sortDescending: json['sortDescending'] as bool? ?? true,
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Map<String, dynamic>? toJson(SearchState state) {
    if (state is SearchSuccess) {
      return {
        'type': 'success',
        'results': state.results.map(mangaToCacheMap).toList(),
        'keywords': state.keywords,
        'currentPage': state.currentPage,
        'lastPage': state.lastPage,
        'sortDescending': state.sortDescending,
      };
    }
    return null;
  }
}
