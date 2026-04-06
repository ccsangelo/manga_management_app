import 'package:manga_recommendation_app/models/manga.dart';

// Home page states
class HomeState {
  final HomeStatus popularStatus;
  final HomeStatus latestStatus;
  final HomeStatus recommendedStatus;
  final HomeStatus randomStatus;
  final List<Manga> popularManga;
  final List<Manga> latestManga;
  final List<Manga> recommendedManga;
  final List<Manga> randomManga;
  final String? popularError;
  final String? latestError;
  final String? recommendedError;
  final String? randomError;
  final bool recommendedHasHistory;

  const HomeState({
    this.popularStatus = HomeStatus.loading,
    this.latestStatus = HomeStatus.loading,
    this.recommendedStatus = HomeStatus.loading,
    this.randomStatus = HomeStatus.loading,
    this.popularManga = const [],
    this.latestManga = const [],
    this.recommendedManga = const [],
    this.randomManga = const [],
    this.popularError,
    this.latestError,
    this.recommendedError,
    this.randomError,
    this.recommendedHasHistory = false,
  });

  HomeState copyWith({
    HomeStatus? popularStatus,
    HomeStatus? latestStatus,
    HomeStatus? recommendedStatus,
    HomeStatus? randomStatus,
    List<Manga>? popularManga,
    List<Manga>? latestManga,
    List<Manga>? recommendedManga,
    List<Manga>? randomManga,
    String? popularError,
    String? latestError,
    String? recommendedError,
    String? randomError,
    bool? recommendedHasHistory,
  }) {
    return HomeState(
      popularStatus: popularStatus ?? this.popularStatus,
      latestStatus: latestStatus ?? this.latestStatus,
      recommendedStatus: recommendedStatus ?? this.recommendedStatus,
      randomStatus: randomStatus ?? this.randomStatus,
      popularManga: popularManga ?? this.popularManga,
      latestManga: latestManga ?? this.latestManga,
      recommendedManga: recommendedManga ?? this.recommendedManga,
      randomManga: randomManga ?? this.randomManga,
      popularError: popularError ?? this.popularError,
      latestError: latestError ?? this.latestError,
      recommendedError: recommendedError ?? this.recommendedError,
      randomError: randomError ?? this.randomError,
      recommendedHasHistory: recommendedHasHistory ?? this.recommendedHasHistory,
    );
  }
}

enum HomeStatus { loading, loaded, error }
