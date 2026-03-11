// Search event definitions
abstract class SearchEvent {}

// Keyword-based search request
class SearchRequested extends SearchEvent {
  final String keywords;
  final bool nsfwEnabled;

  SearchRequested(this.keywords, {this.nsfwEnabled = false});
}

// Paginated search request
class PageRequested extends SearchEvent {
  final String keywords;
  final int page;
  final bool nsfwEnabled;

  PageRequested(this.keywords, this.page, {this.nsfwEnabled = false});
}

// Random manga request
class RandomRequested extends SearchEvent {
  final bool nsfwEnabled;

  RandomRequested({this.nsfwEnabled = false});
}

