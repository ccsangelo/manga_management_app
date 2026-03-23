import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final MangaService _mangaService;

  SearchBloc({required MangaService mangaService})
      : _mangaService = mangaService,
        super(SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
  }

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    final result = await _mangaService.searchManga(
      event.keywords,
      page: event.page,
      nsfwEnabled: event.nsfwEnabled,
      sortDescending: event.sortDescending,
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
  }
}
