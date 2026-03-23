import 'package:hive_flutter/hive_flutter.dart';

// Hive-backed persistent store for user-assigned reading statuses
class MangaStatusService {
  MangaStatusService._();
  static final MangaStatusService instance = MangaStatusService._();

  static const _boxName = 'manga_statuses';
  late final Box<String> _box;

  static const List<String> statusOptions = [
    'Reading',
    'Completed',
    'Dropped',
    'On Hold',
    'Want to Read',
  ];

  static Future<void> init() async {
    instance._box = await Hive.openBox<String>(_boxName);
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
}
