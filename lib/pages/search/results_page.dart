import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_event.dart';
import 'package:manga_recommendation_app/bloc/search/search_state.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/widgets/manga_card.dart';

// Search results with card grid, infinite scroll, and sort toggle
class ResultsPage extends StatefulWidget {
  final String keywords;
  final bool nsfwEnabled;
  final bool orMode;

  const ResultsPage({
    super.key,
    required this.keywords,
    this.nsfwEnabled = false,
    this.orMode = false,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _sortDescending = true;
  Timer? _scrollDebounce;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _toggleSort() {
    setState(() => _sortDescending = !_sortDescending);
    final state = context.read<SearchBloc>().state;
    final keywords =
        state is SearchSuccess ? state.keywords : widget.keywords;
    context.read<SearchBloc>().add(
          SearchRequested(
            keywords,
            nsfwEnabled: widget.nsfwEnabled,
            sortDescending: _sortDescending,
            orMode: widget.orMode,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _sortDescending
                ? 'Score: High to Low'
                : 'Score: Low to High',
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state.results.isEmpty) {
            return const Center(
              child: Text(
                'No results found.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 200) {
                _scrollDebounce?.cancel();
                _scrollDebounce = Timer(
                  const Duration(milliseconds: 300),
                  () => context.read<SearchBloc>().add(LoadMoreResults()),
                );
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.results.length +
                  (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.results.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2),
                    ),
                  );
                }
                return GridMangaCard(manga: state.results[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

