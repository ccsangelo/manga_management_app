abstract class SearchEvent {}

class SearchRequested extends SearchEvent {
  final String keywords;
  final int page;
  final bool nsfwEnabled;
  final bool sortDescending;

  SearchRequested(
    this.keywords, {
    this.page = 1,
    this.nsfwEnabled = false,
    this.sortDescending = true,
  });
}

