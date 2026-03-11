import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/pages/manga_info.dart';

// Paginated search results list
class ResultsPage extends StatefulWidget {
  final List<Manga> results;
  final String keywords;
  final bool nsfwEnabled;

  const ResultsPage({
    super.key,
    required this.results,
    required this.keywords,
    this.nsfwEnabled = false,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final TextEditingController _goToController = TextEditingController();

  void _goToPage(int page, String keywords, int lastPage) {
    if (page < 1 || page > lastPage) return;
    context.read<SearchBloc>().add(PageRequested(
          keywords,
          page,
          nsfwEnabled: widget.nsfwEnabled,
        ));
  }

  @override
  void dispose() {
    _goToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! SearchSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = state.results;
          final currentPage = state.currentPage;
          final lastPage = state.lastPage;
          final keywords = state.keywords;

          if (results.isEmpty) {
            return const Center(
              child: Text(
                'No results found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // Manga list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: results.length,
                  separatorBuilder: (context2, index2) =>
                      const Divider(color: Color(0xFF2A2A2A)),
                  itemBuilder: (context, index) {
                    final manga = results[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RandomPage(manga: manga),
                        ),
                      ),
                      leading: manga.imageUrl != null
                          ? Image.network(
                              manga.imageUrl!,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                width: 50,
                                height: 70,
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : null,
                      title: Text(
                        manga.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: manga.score > 0
                          ? Text(
                              'Score: ${manga.score.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                    );
                  },
                ),
              ),
              // Pagination
              _buildPaginationBar(currentPage, lastPage, keywords),
            ],
          );
        },
      ),
    );
  }

  // Bottom pagination bar with page buttons and go-to input
  Widget _buildPaginationBar(int currentPage, int lastPage, String keywords) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous page
          _navButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 1
                ? () => _goToPage(currentPage - 1, keywords, lastPage)
                : null,
          ),
          const SizedBox(width: 4),
          ..._buildPageButtons(currentPage, lastPage, keywords),
          const SizedBox(width: 4),
          // Next page
          _navButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < lastPage
                ? () => _goToPage(currentPage + 1, keywords, lastPage)
                : null,
          ),
          const SizedBox(width: 12),
          // Go-to page input
          const Text(
              'Go to', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            height: 28,
            child: TextField(
              controller: _goToController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: '',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null) {
                  _goToPage(page, keywords, lastPage);
                  _goToController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Generates numbered page buttons with ellipsis gaps
  List<Widget> _buildPageButtons(
      int currentPage, int lastPage, String keywords) {
    final pages = <int>{1, lastPage};

    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i >= 1 && i <= lastPage) pages.add(i);
    }

    final sortedPages = pages.toList()..sort();
    final widgets = <Widget>[];

    for (var i = 0; i < sortedPages.length; i++) {
      // Ellipsis for gaps between page numbers
      if (i > 0 && sortedPages[i] - sortedPages[i - 1] > 1) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey)),
          ),
        );
      }

      final page = sortedPages[i];
      final isActive = page == currentPage;

      widgets.add(
        GestureDetector(
          onTap: isActive ? null : () => _goToPage(page, keywords, lastPage),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? Colors.deepPurple : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[400],
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  // Navigation arrow button (previous/next)
  Widget _navButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey[700],
          size: 18,
        ),
      ),
    );
  }
}
