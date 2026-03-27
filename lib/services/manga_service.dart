import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manga_recommendation_app/config/app_config.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/models/manga_search_result.dart';

// Jikan API service with Hive-backed caching and Either-based error handling
class MangaService {
  static const _nsfwGenres = ['ecchi', 'erotica', 'hentai'];
  static const _maxRandomRetries = 5;
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
  }) async {
    final cacheKey = '${keywords}_${page}_${nsfwEnabled}_$sortDescending';
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
  Future<Either<String, Manga>> getRandom({bool nsfwEnabled = false}) async {
    for (var attempt = 0; attempt < _maxRandomRetries; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      try {
        final response =
            await _dio.get<Map<String, dynamic>>('$_baseUrl/random/manga');
        final manga =
            Manga.fromJson(response.data!['data'] as Map<String, dynamic>);

        if (nsfwEnabled || !_isNsfw(manga)) return Right(manga);
      } on DioException catch (e) {
        return Left(_dioErrorMessage(e));
      }
    }

    return Left(
        'Could not find a non-NSFW manga after $_maxRandomRetries attempts. Please try again.');
  }
}

