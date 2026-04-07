import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

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
