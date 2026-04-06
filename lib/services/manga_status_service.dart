import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

// Hive-backed persistent store for user-assigned reading statuses and genres
class MangaStatusService {
  MangaStatusService._();
  static final MangaStatusService instance = MangaStatusService._();

  static const _boxName = 'manga_statuses';
  static const _genresBoxName = 'manga_genres';
  late final Box<String> _box;
  late final Box<String> _genresBox;

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
  }

  String? getStatus(int malId) => _box.get(malId.toString());

  void setStatus(int malId, String? status) {
    final key = malId.toString();
    if (status == null) {
      _box.delete(key);
    } else {
      _box.put(key, status);
    }
  }

  // Stores the genres for a manga entry (called whenever a status is set)
  void saveGenres(int malId, List<String> genres) {
    if (genres.isEmpty) return;
    _genresBox.put(malId.toString(), jsonEncode(genres));
  }

  // Returns up to 5 most-frequent genres across all Reading and Completed manga
  List<String> getReadingAndCompletedGenres() {
    const activeStatuses = {'Reading', 'Completed'};
    final genreCount = <String, int>{};

    for (final key in _box.keys) {
      final status = _box.get(key as String);
      if (status == null || !activeStatuses.contains(status)) continue;

      final rawGenres = _genresBox.get(key);
      if (rawGenres == null) continue;

      final genres = List<String>.from(jsonDecode(rawGenres) as List);
      for (final genre in genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }

    final sorted = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => e.key).toList();
  }
}
