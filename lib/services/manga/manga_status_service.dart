import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';

// Hive-backed persistent store for user-assigned reading statuses and genres
class MangaStatusService extends ChangeNotifier {
  MangaStatusService._();
  static final MangaStatusService instance = MangaStatusService._();

  static const _boxName = 'manga_statuses';
  static const _genresBoxName = 'manga_genres';
  static const _mangaDataBoxName = 'manga_data';
  late final Box<String> _box;
  late final Box<String> _genresBox;
  late final Box<String> _mangaDataBox;

  // Cached genre computation to avoid repeated Hive iteration + JSON decoding
  List<String>? _cachedTopGenres;
  DateTime? _lastGenreComputeTime;
  static const _genreCacheDuration = Duration(minutes: 5);

  static const List<String> statusOptions = [
    'Reading',
    'Completed',
    'Dropped',
    'On Hold',
    'Want to Read',
  ];

  static Future<void> init() async {
    instance._box = await Hive.openBox<String>(_boxName);
    instance._genresBox = await Hive.openBox<String>(_genresBoxName);
    instance._mangaDataBox = await Hive.openBox<String>(_mangaDataBoxName);
  }

  String? getStatus(int malId) => _box.get(malId.toString());

  void setStatus(int malId, String? status) {
    final key = malId.toString();
    if (status == null) {
      _box.delete(key);
    } else {
      _box.put(key, status);
    }
    _invalidateGenreCache();
    notifyListeners();
  }

  // Stores the genres for a manga entry (called whenever a status is set)
  void saveGenres(int malId, List<String> genres) {
    if (genres.isEmpty) return;
    _genresBox.put(malId.toString(), jsonEncode(genres));
  }

  // Persists a manga's display data so the reading list can show cards offline
  void saveMangaData(Manga manga) {
    _mangaDataBox.put(
      manga.malId.toString(),
      jsonEncode(mangaToCacheMap(manga)),
    );
  }

  // Returns all manga that have a given status
  List<Manga> getMangaByStatus(String status) {
    final result = <Manga>[];
    for (final key in _box.keys) {
      if (_box.get(key as String) != status) continue;
      final raw = _mangaDataBox.get(key);
      if (raw == null) continue;
      try {
        result.add(mangaFromCacheMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        ));
      } catch (_) {}
    }
    return result;
  }

  // Returns a map of status → manga list for all statuses that have entries
  Map<String, List<Manga>> getAllGroupedByStatus() {
    final grouped = <String, List<Manga>>{};
    for (final key in _box.keys) {
      final status = _box.get(key as String);
      if (status == null) continue;
      final raw = _mangaDataBox.get(key);
      if (raw == null) continue;
      try {
        final manga = mangaFromCacheMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        (grouped[status] ??= []).add(manga);
      } catch (_) {}
    }
    return grouped;
  }

  // Returns up to 5 most-frequent genres across all Reading and Completed manga
  List<String> getReadingAndCompletedGenres() {
    if (_cachedTopGenres != null &&
        _lastGenreComputeTime != null &&
        DateTime.now().difference(_lastGenreComputeTime!) < _genreCacheDuration) {
      return _cachedTopGenres!;
    }

    const activeStatuses = {'Reading', 'Completed'};
    final genreCount = <String, int>{};

    for (final key in _box.keys) {
      final status = _box.get(key as String);
      if (status == null || !activeStatuses.contains(status)) continue;

      final rawGenres = _genresBox.get(key);
      if (rawGenres == null) continue;

      try {
        final genres = List<String>.from(jsonDecode(rawGenres) as List);
        for (final genre in genres) {
          genreCount[genre] = (genreCount[genre] ?? 0) + 1;
        }
      } catch (_) {
        // Skip entries with corrupted JSON
      }
    }

    final sorted = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _cachedTopGenres = sorted.take(5).map((e) => e.key).toList();
    _lastGenreComputeTime = DateTime.now();
    return _cachedTopGenres!;
  }

  // Invalidate genre cache when status changes
  void _invalidateGenreCache() {
    _cachedTopGenres = null;
    _lastGenreComputeTime = null;
  }

  // Clears all stored statuses, genres, and manga data (used on logout)
  Future<void> clearAll() async {
    await _box.clear();
    await _genresBox.clear();
    await _mangaDataBox.clear();
    _invalidateGenreCache();
    notifyListeners();
  }
}
