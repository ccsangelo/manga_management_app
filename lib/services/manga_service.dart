import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/models/manga_search_result.dart';

// Handles all Jikan API interactions for manga data
class MangaService {
  static const _baseUrl = 'https://api.jikan.moe/v4';
  static const _nsfwGenres = ['ecchi', 'erotica', 'hentai'];
  static const _maxRandomRetries = 5;

  final http.Client _client;
  Map<String, int>? _genreMap;

  MangaService({http.Client? client}) : _client = client ?? http.Client();

  // Fetches and caches genre/theme ID mappings from Jikan
  Future<Map<String, int>> _getGenreMap() async {
    if (_genreMap != null) return _genreMap!;

    final uri = Uri.parse('$_baseUrl/genres/manga');
    final response = await _client.get(uri);

    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>;

    _genreMap = {
      for (final item in items)
        (item['name'] as String).toLowerCase(): item['mal_id'] as int,
    };

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

    final genreMap = await _getGenreMap();
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

    final queryParams = <String, String>{
      'limit': '25',
      'page': page.toString(),
      'order_by': 'score',
      'sort': 'desc',
      'genres': genreIds.join(','),
    };

    // API-level adult content filter when NSFW is disabled
    if (!nsfwEnabled) queryParams['sfw'] = 'true';

    final uri =
        Uri.parse('$_baseUrl/manga').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search manga (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>?;

    var results = items
        .map((item) => Manga.fromJson(item as Map<String, dynamic>))
        .toList();

    // Client-side NSFW filtering for ecchi/erotica/hentai
    if (!nsfwEnabled) {
      results = results.where((manga) => !_isNsfw(manga)).toList();
    }

    return MangaSearchResult(
      results: results,
      currentPage: page,
      lastPage: pagination?['last_visible_page'] as int? ?? 1,
      hasNextPage: pagination?['has_next_page'] as bool? ?? false,
    );
  }

  // Matches a keyword to a genre/theme ID (exact match, then partial)
  int? _findGenreId(String keyword, Map<String, int> genreMap) {
    if (genreMap.containsKey(keyword)) return genreMap[keyword];

    for (final entry in genreMap.entries) {
      if (entry.key.contains(keyword) || keyword.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  // Checks if manga has NSFW genres (ecchi, erotica, hentai)
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

  // Fetches a random manga with retry logic for NSFW filtering
  Future<Manga> getRandom({bool nsfwEnabled = false}) async {
    for (var attempt = 0; attempt < _maxRandomRetries; attempt++) {
      // Rate limit delay between retries
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }

      final uri = Uri.parse('$_baseUrl/random/manga');
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to fetch random manga (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final manga = Manga.fromJson(data['data'] as Map<String, dynamic>);

      if (nsfwEnabled || !_isNsfw(manga)) return manga;
    }

    throw Exception(
        'Could not find a non-NSFW manga after $_maxRandomRetries attempts. Please try again.');
  }
}
