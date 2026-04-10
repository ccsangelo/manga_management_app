import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_state.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/widgets/manga_card.dart';

// Generic paginated manga list page
class PaginatedListPage extends StatefulWidget {
  const PaginatedListPage({super.key});

  @override
  State<PaginatedListPage> createState() => _PaginatedListPageState();
}

class _PaginatedListPageState extends State<PaginatedListPage> {
  Timer? _scrollDebounce;

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<PaginatedListCubit, PaginatedListState>(
        builder: (context, state) {
          if (state.status == PaginatedStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (state.status == PaginatedStatus.error && state.manga.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.error ?? 'Something went wrong.',
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.read<PaginatedListCubit>().loadFirstPage(),
                    child: const Text('Retry',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                ],
              ),
            );
          }

          if (state.manga.isEmpty) {
            return const Center(
              child: Text('No manga found.', style: TextStyle(color: Colors.grey)),
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
                  () => context.read<PaginatedListCubit>().loadNextPage(),
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
              itemCount: state.manga.length +
                  (state.status == PaginatedStatus.loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.manga.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2),
                    ),
                  );
                }
                return GridMangaCard(manga: state.manga[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
