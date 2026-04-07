import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manga_recommendation_app/config/app_config.dart';
import 'package:manga_recommendation_app/models/anime.dart';
import 'package:manga_recommendation_app/models/genre_item.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/models/manga_search_result.dart';

// Jikan API service with Hive-backed caching and Either-based error handling
class MangaService {
  static const _nsfwGenres = ['ecchi', 'erotica', 'hentai'];
  static const _maxCacheSize = 50;
  static const _searchCacheBoxName = 'search_cache';
  static const _cacheDuration = Duration(hours: 1);

  String get _baseUrl => AppConfig.baseUrl;

  final Dio _dio;
  Map<String, int>? _genreMap;
  static late Box<String> _cacheBox;

  MangaService({Dio? dio}) : _dio = dio ?? Dio();

  static Future<void> init() async {
    _cacheBox = await Hive.openBox<String>(_searchCacheBoxName);
    _removeExpiredEntries();
  }

  static void _removeExpiredEntries() {
    final keysToDelete = <dynamic>[];
    for (final key in _cacheBox.keys) {
      final raw = _cacheBox.get(key);
      if (raw == null) continue;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final cachedAt =
            DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int);
        if (DateTime.now().difference(cachedAt) > _cacheDuration) {
          keysToDelete.add(key);
        }
      } catch (_) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      _cacheBox.delete(key);
    }
  }

  // Clears one cache entry by key, or all entries if no key is given.
  Future<void> invalidateSearchCache({String? cacheKey}) async {
    if (cacheKey != null) {
      await _cacheBox.delete(cacheKey);
    } else {
      await _cacheBox.clear();
    }
  }

  MangaSearchResult? _getCachedResult(String cacheKey) {
    final raw = _cacheBox.get(cacheKey);
    if (raw == null) return null;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int);

      if (DateTime.now().difference(cachedAt) > _cacheDuration) {
        _cacheBox.delete(cacheKey);
        return null;
      }

      return MangaSearchResult(
        currentPage: map['currentPage'] as int,
        lastPage: map['lastPage'] as int,
        hasNextPage: map['hasNextPage'] as bool,
        results: (map['results'] as List<dynamic>)
            .map((e) => mangaFromCacheMap(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      _cacheBox.delete(cacheKey);
      return null;
    }
  }

  Future<void> _putCachedResult(String cacheKey, MangaSearchResult result) async {
    if (_cacheBox.length >= _maxCacheSize) {
      await _cacheBox.delete(_cacheBox.keys.first);
    }
    await _cacheBox.put(cacheKey, jsonEncode({
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'currentPage': result.currentPage,
      'lastPage': result.lastPage,
      'hasNextPage': result.hasNextPage,
      'results': result.results.map(mangaToCacheMap).toList(),
    }));
  }

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
  Future<Either<String, Map<String, int>>> _getGenreMap() async {
    if (_genreMap != null) return Right(_genreMap!);

    try {
      final response =
          await _dio.get<Map<String, dynamic>>('$_baseUrl/genres/manga');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];

      _genreMap = {
        for (final item in items)
          (item['name'] as String).toLowerCase(): item['mal_id'] as int,
      };
      return Right(_genreMap!);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Searches manga by comma-separated genre/theme keywords
  Future<Either<String, MangaSearchResult>> searchManga(
    String keywords, {
    int page = 1,
    bool nsfwEnabled = false,
    bool sortDescending = true,
    bool orMode = false,
  }) async {
    final cacheKey = '${keywords}_${page}_${nsfwEnabled}_${sortDescending}_$orMode';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached);

    final keywordList = keywords
        .split(',')
        .map((k) => k.trim().toLowerCase())
        .where((k) => k.isNotEmpty)
        .toList();

    if (keywordList.isEmpty) {
      return const Right(MangaSearchResult(
        results: [],
        currentPage: 1,
        lastPage: 1,
        hasNextPage: false,
      ));
    }

    final genreResult = await _getGenreMap();
    if (genreResult.isLeft()) {
      return Left(genreResult.fold((l) => l, (_) => ''));
    }
    final genreMap = genreResult.getOrElse(() => {});

    final genreIds = <int>{};
    for (final keyword in keywordList) {
      final id = _findGenreId(keyword, genreMap);
      if (id != null) genreIds.add(id);
    }

    if (genreIds.isEmpty) {
      return const Right(MangaSearchResult(
        results: [],
        currentPage: 1,
        lastPage: 1,
        hasNextPage: false,
      ));
    }

    // OR mode: make one call per genre, merge & deduplicate
    if (orMode && genreIds.length > 1) {
      return _searchMangaOr(
        genreIds: genreIds,
        nsfwEnabled: nsfwEnabled,
        sortDescending: sortDescending,
        cacheKey: cacheKey,
      );
    }

    final queryParams = <String, dynamic>{
      'limit': '25',
      'page': page.toString(),
      'order_by': 'score',
      'sort': sortDescending ? 'desc' : 'asc',
      'genres': genreIds.join(','),
    };

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

      if (!nsfwEnabled) {
        results = results.where((manga) => !_isNsfw(manga)).toList();
      }

      final searchResult = MangaSearchResult(
        results: results,
        currentPage: page,
        lastPage: pagination?['last_visible_page'] as int? ?? 1,
        hasNextPage: pagination?['has_next_page'] as bool? ?? false,
      );

      await _putCachedResult(cacheKey, searchResult);

      return Right(searchResult);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
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

  // OR mode search: one request per genre ID, merge & deduplicate, sort by score
  Future<Either<String, MangaSearchResult>> _searchMangaOr({
    required Set<int> genreIds,
    required bool nsfwEnabled,
    required bool sortDescending,
    required String cacheKey,
  }) async {
    final seen = <int>{};
    final merged = <Manga>[];

    for (final id in genreIds) {
      try {
        final params = <String, dynamic>{
          'limit': '25',
          'page': '1',
          'order_by': 'score',
          'sort': sortDescending ? 'desc' : 'asc',
          'genres': id.toString(),
        };
        if (!nsfwEnabled) params['sfw'] = 'true';

        final response = await _dio.get<Map<String, dynamic>>(
          '$_baseUrl/manga',
          queryParameters: params,
        );
        final items = response.data!['data'] as List<dynamic>;
        for (final item in items) {
          final manga = Manga.fromJson(item as Map<String, dynamic>);
          if (!nsfwEnabled && _isNsfw(manga)) continue;
          if (seen.add(manga.malId)) merged.add(manga);
        }
      } on DioException catch (e) {
        return Left(_dioErrorMessage(e));
      }

      // Stagger requests to respect Jikan rate limit
      await Future.delayed(const Duration(milliseconds: 400));
    }

    // Sort merged results
    merged.sort((a, b) => sortDescending
        ? b.score.compareTo(a.score)
        : a.score.compareTo(b.score));

    final searchResult = MangaSearchResult(
      results: merged.take(25).toList(),
      currentPage: 1,
      lastPage: 1,
      hasNextPage: false,
    );

    await _putCachedResult(cacheKey, searchResult);
    return Right(searchResult);
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

  // Fetches the most popular manga (10, currently publishing for recency)
  Future<Either<String, List<Manga>>> getPopular() async {
    const cacheKey = 'popular_now';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached.results);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/manga',
        queryParameters: {
          'status': 'publishing',
          'order_by': 'popularity',
          'sort': 'asc',
          'limit': '10',
          'sfw': 'true',
        },
      );
      final items = response.data!['data'] as List<dynamic>;
      final results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();

      await _putCachedResult(
        cacheKey,
        MangaSearchResult(results: results, currentPage: 1, lastPage: 1, hasNextPage: false),
      );

      return Right(results);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Fetches the most recently updated/publishing manga (10)
  Future<Either<String, List<Manga>>> getLatestUpdates() async {
    const cacheKey = 'latest_updates';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached.results);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/manga',
        queryParameters: {
          'status': 'publishing',
          'order_by': 'start_date',
          'sort': 'desc',
          'limit': '10',
          'sfw': 'true',
        },
      );
      final items = response.data!['data'] as List<dynamic>;
      final results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();

      await _putCachedResult(
        cacheKey,
        MangaSearchResult(results: results, currentPage: 1, lastPage: 1, hasNextPage: false),
      );

      return Right(results);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Fetches recommended manga based on the user's top genres from their reading history
  Future<Either<String, List<Manga>>> getRecommended(List<String> genres) async {
    if (genres.isEmpty) return const Right([]);

    final keywords = genres.take(3).join(', ');
    final cacheKey = 'recommended_${genres.take(3).join('_')}';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached.results);

    final result = await searchManga(keywords, nsfwEnabled: false);
    if (result.isLeft()) return result.fold(Left.new, (_) => const Right([]));

    final top10 = result.getOrElse(() => const MangaSearchResult(
      results: [], currentPage: 1, lastPage: 1, hasNextPage: false,
    )).results.take(10).toList();

    await _putCachedResult(
      cacheKey,
      MangaSearchResult(results: top10, currentPage: 1, lastPage: 1, hasNextPage: false),
    );
    return Right(top10);
  }

  // Fetches a random batch of manga (10)
  Future<Either<String, List<Manga>>> getRandomBatch() async {
    try {
      final page = Random().nextInt(200) + 1;
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/manga',
        queryParameters: {
          'page': page.toString(),
          'limit': '10',
          'sfw': 'true',
          'min_score': '1',
          'order_by': 'members',
          'sort': 'desc',
        },
      );
      final items = response.data!['data'] as List<dynamic>;
      final results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();
      return Right(results);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Paginated latest updates (currently publishing manga ordered by popularity)
  Future<Either<String, MangaSearchResult>> getLatestUpdatesPaginated({int page = 1}) async {
    final cacheKey = 'latest_updates_page_$page';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached);

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/manga',
        queryParameters: {
          'status': 'publishing',
          'order_by': 'start_date',
          'sort': 'desc',
          'limit': '25',
          'page': page.toString(),
          'sfw': 'true',
        },
      );
      final data = response.data!;
      final items = data['data'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>?;

      final results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();

      final searchResult = MangaSearchResult(
        results: results,
        currentPage: page,
        lastPage: pagination?['last_visible_page'] as int? ?? 1,
        hasNextPage: pagination?['has_next_page'] as bool? ?? false,
      );

      await _putCachedResult(cacheKey, searchResult);
      return Right(searchResult);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Fetches genre/theme/demographic categories from Jikan
  // filter: 'genres', 'explicit_genres', 'themes', 'demographics'
  final Map<String, List<GenreItem>> _genreListCache = {};

  Future<Either<String, List<GenreItem>>> getMangaGenres({
    String filter = 'genres',
  }) async {
    if (_genreListCache.containsKey(filter)) {
      return Right(_genreListCache[filter]!);
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/genres/manga',
        queryParameters: {'filter': filter},
      );
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      final genres = items.map((e) => GenreItem.fromJson(e as Map<String, dynamic>)).toList();
      _genreListCache[filter] = genres;
      return Right(genres);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Fetches paginated top manga with optional type/filter
  Future<Either<String, MangaSearchResult>> getTopMangaPaginated({
    String? type,
    String? filter,
    int page = 1,
  }) async {
    final cacheKey = 'top_manga_${type ?? 'all'}_${filter ?? 'none'}_$page';
    final cached = _getCachedResult(cacheKey);
    if (cached != null) return Right(cached);

    try {
      final params = <String, dynamic>{
        'page': page.toString(),
        'limit': '25',
      };
      if (type != null) params['type'] = type;
      if (filter != null) params['filter'] = filter;

      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/top/manga',
        queryParameters: params,
      );
      final data = response.data!;
      final items = data['data'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>?;

      final results = items
          .map((item) => Manga.fromJson(item as Map<String, dynamic>))
          .toList();

      final searchResult = MangaSearchResult(
        results: results,
        currentPage: page,
        lastPage: pagination?['last_visible_page'] as int? ?? 1,
        hasNextPage: pagination?['has_next_page'] as bool? ?? false,
      );

      await _putCachedResult(cacheKey, searchResult);
      return Right(searchResult);
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }

  // Fetches paginated anime from /top/anime
  Future<Either<String, AnimeSearchResult>> getTopAnimePaginated({
    String? filter,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page.toString(),
        'limit': '25',
        'sfw': 'true',
      };
      if (filter != null) params['filter'] = filter;

      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/top/anime',
        queryParameters: params,
      );
      final data = response.data!;
      final items = data['data'] as List<dynamic>;
      final pagination = data['pagination'] as Map<String, dynamic>?;

      final results = items
          .map((item) => Anime.fromJson(item as Map<String, dynamic>))
          .toList();

      return Right(AnimeSearchResult(
        results: results,
        currentPage: page,
        lastPage: pagination?['last_visible_page'] as int? ?? 1,
        hasNextPage: pagination?['has_next_page'] as bool? ?? false,
      ));
    } on DioException catch (e) {
      return Left(_dioErrorMessage(e));
    }
  }
}

