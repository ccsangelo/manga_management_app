// In-memory store for user-assigned reading statuses per manga ID
class MangaStatusService {
  MangaStatusService._();
  static final MangaStatusService instance = MangaStatusService._();

  final Map<int, String> _statuses = {};

  static const List<String> statusOptions = [
    'Reading',
    'Completed',
    'Dropped',
    'On Hold',
    'Want to Read',
  ];

  String? getStatus(int malId) => _statuses[malId];

  void setStatus(int malId, String? status) {
    if (status == null) {
      _statuses.remove(malId);
    } else {
      _statuses[malId] = status;
    }
  }
}
