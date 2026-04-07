// Search events
abstract class SearchEvent {}

class SearchRequested extends SearchEvent {
  final String keywords;
  final int page;
  final bool nsfwEnabled;
  final bool sortDescending;
  final bool orMode;

  SearchRequested(
    this.keywords, {
    this.page = 1,
    this.nsfwEnabled = false,
    this.sortDescending = true,
    this.orMode = false,
  });
}

