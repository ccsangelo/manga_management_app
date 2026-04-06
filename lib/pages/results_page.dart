import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/models/manga.dart';
import 'package:manga_recommendation_app/services/manga_status_service.dart';

// Search results with pagination, sort/filter, and status display
class ResultsPage extends StatefulWidget {
  final String keywords;
  final bool nsfwEnabled;

  const ResultsPage({
    super.key,
    required this.keywords,
    this.nsfwEnabled = false,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _goToController = TextEditingController();
  bool _sortDescending = true;
  final Set<String> _selectedStatuses = {};

  void _goToPage(int page, String keywords, int lastPage) {
    if (page < 1 || page > lastPage) return;
    context.read<SearchBloc>().add(
          SearchRequested(
            keywords,
            page: page,
            nsfwEnabled: widget.nsfwEnabled,
            sortDescending: _sortDescending,
          ),
        );
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
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Sort & Filter',
            onPressed: _showSortFilterSheet,
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchFailure) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          if (state is! SearchSuccess) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = _applyStatusFilter(state.results);

          if (results.isEmpty) {
            return Center(
              child: Text(
                state.results.isEmpty
                    ? 'No results found.'
                    : 'No manga match the current filter.',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              if (_selectedStatuses.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.deepPurple.withAlpha(30),
                  child: Text(
                    'Filtering by: ${_selectedStatuses.join(', ')}',
                    style:
                        const TextStyle(color: Colors.deepPurple, fontSize: 12),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: results.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: Color(0xFF2A2A2A)),
                  itemBuilder: (context, index) =>
                      _buildMangaTile(results[index]),
                ),
              ),
              _buildPaginationBar(
                  state.currentPage, state.lastPage, state.keywords),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMangaTile(Manga manga) {
    final mangaStatus = MangaStatusService.instance.getStatus(manga.malId);
    return ListTile(
      onTap: () async {
        await context.push('/manga', extra: manga);
        if (mounted) setState(() {}); // Refresh status shown in list
      },
      leading: manga.imageUrl != null
          ? Image.network(
              manga.imageUrl!,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 50,
                height: 70,
                color: Colors.grey[800],
                child:
                    const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            )
          : null,
      title: Text(manga.title, style: const TextStyle(color: Colors.white)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (manga.score > 0)
            Text(
              'Score: ${manga.score.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.grey),
            ),
          if (mangaStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark, color: Colors.deepPurple, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    mangaStatus,
                    style: const TextStyle(
                        color: Colors.deepPurple, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Applies status filter only (sort is handled by the API)
  List<Manga> _applyStatusFilter(List<Manga> source) {
    if (_selectedStatuses.isEmpty) return source;
    return source.where((m) {
      final status = MangaStatusService.instance.getStatus(m.malId);
      return status != null && _selectedStatuses.contains(status);
    }).toList();
  }

  void _showSortFilterSheet() {
    bool tempDescending = _sortDescending;
    final tempStatuses = Set<String>.from(_selectedStatuses);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Sort & Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Sort by Score',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                RadioGroup<bool>(
                  groupValue: tempDescending,
                  onChanged: (v) =>
                      setSheetState(() => tempDescending = v ?? tempDescending),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<bool>(
                        value: true,
                        activeColor: Colors.deepPurple,
                        title: const Text('Descending',
                            style: TextStyle(color: Colors.white)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        value: false,
                        activeColor: Colors.deepPurple,
                        title: const Text('Ascending',
                            style: TextStyle(color: Colors.white)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 4),

                const Text(
                  'Filter by Status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                ...MangaStatusService.statusOptions.map((status) =>
                    CheckboxListTile(
                      value: tempStatuses.contains(status),
                      activeColor: Colors.deepPurple,
                      checkColor: Colors.white,
                      title: Text(status,
                          style: const TextStyle(color: Colors.white)),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (checked) => setSheetState(() {
                        if (checked == true) {
                          tempStatuses.add(status);
                        } else {
                          tempStatuses.remove(status);
                        }
                      }),
                    )),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.deepPurple),
                    onPressed: () {
                      final sortChanged = _sortDescending != tempDescending;
                      setState(() {
                        _sortDescending = tempDescending;
                        _selectedStatuses
                          ..clear()
                          ..addAll(tempStatuses);
                      });
                      Navigator.pop(ctx);
                      // Re-fetch from API with new sort order
                      if (sortChanged) {
                        final state = context.read<SearchBloc>().state;
                        final keywords = state is SearchSuccess
                            ? state.keywords
                            : widget.keywords;
                        context.read<SearchBloc>().add(
                              SearchRequested(
                                keywords,
                                nsfwEnabled: widget.nsfwEnabled,
                                sortDescending: _sortDescending,
                              ),
                            );
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
          _navButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 1
                ? () => _goToPage(currentPage - 1, keywords, lastPage)
                : null,
          ),
          const SizedBox(width: 4),
          ..._buildPageButtons(currentPage, lastPage, keywords),
          const SizedBox(width: 4),
          _navButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < lastPage
                ? () => _goToPage(currentPage + 1, keywords, lastPage)
                : null,
          ),
          const SizedBox(width: 12),
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

  List<Widget> _buildPageButtons(
      int currentPage, int lastPage, String keywords) {
    final pages = <int>{1, lastPage};
    for (var i = currentPage - 1; i <= currentPage + 1; i++) {
      if (i >= 1 && i <= lastPage) pages.add(i);
    }

    final sortedPages = pages.toList()..sort();
    final widgets = <Widget>[];

    for (var i = 0; i < sortedPages.length; i++) {
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
