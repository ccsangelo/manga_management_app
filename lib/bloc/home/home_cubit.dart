import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/home/home_state.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';

// Cubit that loads all home page sections
class HomeCubit extends Cubit<HomeState> {
  final MangaService _mangaService;
  bool _nsfwEnabled = false;

  HomeCubit({required MangaService mangaService})
      : _mangaService = mangaService,
        super(const HomeState());

  Future<void> load({bool nsfwEnabled = false}) async {
    _nsfwEnabled = nsfwEnabled;
    // Stagger requests to respect Jikan rate limits (3 req/sec).
    // Each section handles its own error state, so failures don't block others.
    try { await _loadPopular(); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    try { await _loadLatest(); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    try { await _loadRecommended(); } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 400));
    try { await _loadRandom(); } catch (_) {}
  }

  Future<void> _loadPopular() async {
    emit(state.copyWith(popularStatus: HomeStatus.loading));
    final result = await _mangaService.getPopular(nsfwEnabled: _nsfwEnabled);
    result.fold(
      (error) => emit(state.copyWith(
        popularStatus: HomeStatus.error,
        popularError: error,
      )),
      (manga) => emit(state.copyWith(
        popularStatus: HomeStatus.loaded,
        popularManga: manga,
      )),
    );
  }

  Future<void> _loadLatest() async {
    emit(state.copyWith(latestStatus: HomeStatus.loading));
    final result = await _mangaService.getLatestUpdates(nsfwEnabled: _nsfwEnabled);
    result.fold(
      (error) => emit(state.copyWith(
        latestStatus: HomeStatus.error,
        latestError: error,
      )),
      (manga) => emit(state.copyWith(
        latestStatus: HomeStatus.loaded,
        latestManga: manga,
      )),
    );
  }

  Future<void> _loadRecommended() async {
    emit(state.copyWith(recommendedStatus: HomeStatus.loading));
    final genres = MangaStatusService.instance.getReadingAndCompletedGenres();
    if (genres.isEmpty) {
      emit(state.copyWith(
        recommendedStatus: HomeStatus.loaded,
        recommendedManga: [],
        recommendedHasHistory: false,
      ));
      return;
    }
    final result = await _mangaService.getRecommended(genres, nsfwEnabled: _nsfwEnabled);
    result.fold(
      (error) => emit(state.copyWith(
        recommendedStatus: HomeStatus.error,
        recommendedError: error,
      )),
      (manga) => emit(state.copyWith(
        recommendedStatus: HomeStatus.loaded,
        recommendedManga: manga,
        recommendedHasHistory: true,
      )),
    );
  }

  Future<void> _loadRandom() async {
    emit(state.copyWith(randomStatus: HomeStatus.loading));
    final result = await _mangaService.getRandomBatch(nsfwEnabled: _nsfwEnabled);
    result.fold(
      (error) => emit(state.copyWith(
        randomStatus: HomeStatus.error,
        randomError: error,
      )),
      (manga) => emit(state.copyWith(
        randomStatus: HomeStatus.loaded,
        randomManga: manga,
      )),
    );
  }

  Future<void> refreshRandom({bool nsfwEnabled = false}) async {
    _nsfwEnabled = nsfwEnabled;
    await _loadRandom();
  }
}
