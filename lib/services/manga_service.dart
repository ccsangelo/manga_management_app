import 'package:dio/dio.dart';
import 'package:manga_recommendation_app/config/app_config.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/models/manga_search_result.dart';

// Exception for search errors
class SearchFailureException implements Exception {
  final String message;
  const SearchFailureException(this.message);
  @override
  String toString() => message;
}

// Exception for random fetch errors
class RandomFetchException implements Exception {
  final String message;
  const RandomFetchException(this.message);
  @override
  String toString() => message;
}

// Jikan API service
class MangaService {
  static const _nsfwGenres = ['ecchi', 'erotica', 'hentai'];
  static const _maxRandomRetries = 5;

  String get _baseUrl => AppConfig.baseUrl;

  final Dio _dio;
  Map<String, int>? _genreMap;

  MangaService({Dio? dio}) : _dio = dio ?? Dio();

  // Maps a DioException to a user-friendly message
  String _dioErrorMessage(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timed out. Please check your internet.',
      DioExceptionType.receiveTimeout =>
        'Server took too long to respond. Try again later.',
      DioExceptionType.badResponse =>
        'The server returned an error. Please try again later.',
      DioExceptionType.connectionError => 'No internet connection.',
      _ => 'An unexpected network error occurred.',
    };
  }

  // Fetches and caches genre/theme ID mappings from Jikan
  Future<Map<String, int>> _getGenreMap() async {
    if (_genreMap != null) return _genreMap!;

    try {
      final response =
          await _dio.get<Map<String, dynamic>>('$_baseUrl/genres/manga');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];

      _genreMap = {
        for (final item in items)
          (item['name'] as String).toLowerCase(): item['mal_id'] as int,
      };
    } on DioException catch (e) {
      _genreMap = {};
      throw SearchFailureException(_dioErrorMessage(e));
    }

    return _genreMap!;
  }

  // Searches manga by comma-separated genre/theme keywords
  Future<MangaSearchResult> searchManga(
    String keywords, {
    int page = 1,
    bool nsfwEnabled = false,
  }) async {
    final keywordList = keywords
        .split(',')
        .map((k) => k.trim().toLowerCase())
        .where((k) => k.isNotEmpty)
        .toList();

    if (keywordList.isEmpty) {
      return const MangaSearchResult(
        results: [],
        currentPage: 1,
        lastPage: 1,
        hasNextPage: false,
      );
    }

    final Map<String, int> genreMap;
    try {
      genreMap = await _getGenreMap();
    } on SearchFailureException {
      rethrow;
    }

    final genreIds = <int>{};
    for (final keyword in keywordList) {
      final id = _findGenreId(keyword, genreMap);
      if (id != null) genreIds.add(id);
    }

    if (genreIds.isEmpty) {
      return const MangaSearchResult(
        results: [],
        currentPage: 1,
        lastPage: 1,
        hasNextPage: false,
      );
    }

    final queryParams = <String, dynamic>{
      'limit': '25',
      'page': page.toString(),
      'order_by': 'score',
      'sort': 'desc',
      'genres': genreIds.join(','),
    };

    // NSFW filter
    if (!nsfwEnabled) queryParams['sfw'] = 'true';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/manga',
        queryParameters: queryParams,
      );

      final data = response.data!;
      final items = data['data'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>?;

      var results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();

      // Remove NSFW results
      if (!nsfwEnabled) {
        results = results.where((manga) => !_isNsfw(manga)).toList();
      }

      return MangaSearchResult(
        results: results,
        currentPage: page,
        lastPage: pagination?['last_visible_page'] as int? ?? 1,
        hasNextPage: pagination?['has_next_page'] as bool? ?? false,
      );
    } on DioException catch (e) {
      throw SearchFailureException(_dioErrorMessage(e));
    }
  }

  // Finds a genre ID by keyword
  int? _findGenreId(String keyword, Map<String, int> genreMap) {
    if (genreMap.containsKey(keyword)) return genreMap[keyword];

    for (final entry in genreMap.entries) {
      if (entry.key.contains(keyword) || keyword.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  // Checks if a manga is NSFW
  bool _isNsfw(Manga manga) {
    for (final keyword in _nsfwGenres) {
      if (manga.genres.any((g) => g.contains(keyword)) ||
          manga.themes.any((t) => t.contains(keyword)) ||
          manga.demographics.any((d) => d.contains(keyword))) {
        return true;
      }
    }
    return false;
  }

  // Fetches a random manga
  Future<Manga> getRandom({bool nsfwEnabled = false}) async {
    for (var attempt = 0; attempt < _maxRandomRetries; attempt++) {
      // Delay between retries
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      try {
        final response = await _dio
            .get<Map<String, dynamic>>('$_baseUrl/random/manga');
        final manga = Manga.fromJson(
            response.data!['data'] as Map<String, dynamic>);

        if (nsfwEnabled || !_isNsfw(manga)) return manga;
      } on DioException catch (e) {
        throw RandomFetchException(_dioErrorMessage(e));
      }
    }

    throw const RandomFetchException(
        'Could not find a non-NSFW manga after $_maxRandomRetries attempts. Please try again.');
  }
}

