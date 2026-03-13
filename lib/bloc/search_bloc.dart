import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

// BLoC managing search and random manga events
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final MangaService _mangaService;

  SearchBloc({required MangaService mangaService})
      : _mangaService = mangaService,
        super(SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
    on<PageRequested>(_onPageRequested);
    on<RandomRequested>(_onRandomRequested);
  }

  // Handles initial keyword search
  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final result = await _mangaService.searchManga(
        event.keywords,
        nsfwEnabled: event.nsfwEnabled,
      );
      emit(SearchSuccess(
        result.results,
        keywords: event.keywords,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
      ));
    } on SearchFailureException catch (e) {
      emit(SearchFailure(e.message));
    } catch (e) {
      emit(SearchFailure('An unexpected error occurred.'));
    }
  }

  // Handles paginated search navigation
  Future<void> _onPageRequested(
    PageRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(SearchLoading());
    try {
      final result = await _mangaService.searchManga(
        event.keywords,
        page: event.page,
        nsfwEnabled: event.nsfwEnabled,
      );
      emit(SearchSuccess(
        result.results,
        keywords: event.keywords,
        currentPage: result.currentPage,
        lastPage: result.lastPage,
      ));
    } on SearchFailureException catch (e) {
      emit(SearchFailure(e.message));
    } catch (e) {
      emit(SearchFailure('An unexpected error occurred.'));
    }
  }

  // Handles random manga fetch
  Future<void> _onRandomRequested(
    RandomRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(RandomLoading());
    try {
      final manga = await _mangaService.getRandom(
        nsfwEnabled: event.nsfwEnabled,
      );
      emit(RandomSuccess(manga));
    } on RandomFetchException catch (e) {
      emit(RandomFailure(e.message));
    } catch (e) {
      emit(RandomFailure('An unexpected error occurred.'));
    }
  }
}
