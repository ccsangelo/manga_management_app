import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_cubit.dart';
import 'package:manga_recommendation_app/bloc/paginated_list/paginated_list_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/models/search_result/manga_search_result.dart';

Manga _manga(int id) => Manga(
      malId: id,
      title: 'Manga $id',
      genres: [],
      themes: [],
      demographics: [],
      magazines: [],
    );

void main() {
  group('PaginatedListCubit', () {
    test('initial state has loading status and empty manga', () {
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async =>
            Right(MangaSearchResult(results: [], currentPage: 1, lastPage: 1, hasNextPage: false)),
      );
      expect(cubit.state.status, PaginatedStatus.loading);
      expect(cubit.state.manga, isEmpty);
      cubit.close();
    });

    test('loadFirstPage emits loaded with manga on success', () async {
      final manga = [_manga(1), _manga(2)];
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async => Right(
          MangaSearchResult(results: manga, currentPage: 1, lastPage: 3, hasNextPage: true),
        ),
      );

      final states = <PaginatedListState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadFirstPage();
      await cubit.stream.first.timeout(const Duration(seconds: 1), onTimeout: () => cubit.state);

      expect(states.any((s) => s.status == PaginatedStatus.loading), isTrue);
      expect(cubit.state.status, PaginatedStatus.loaded);
      expect(cubit.state.manga.length, 2);
      expect(cubit.state.hasNextPage, isTrue);
      expect(cubit.state.currentPage, 1);

      await sub.cancel();
      await cubit.close();
    });

    test('loadFirstPage emits error on failure', () async {
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async => const Left('Network error'),
      );

      await cubit.loadFirstPage();

      expect(cubit.state.status, PaginatedStatus.error);
      expect(cubit.state.error, 'Network error');
      expect(cubit.state.manga, isEmpty);

      await cubit.close();
    });

    test('loadNextPage appends results and increments page', () async {
      int callCount = 0;
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async {
          callCount++;
          return Right(MangaSearchResult(
            results: [_manga(page * 10 + 1), _manga(page * 10 + 2)],
            currentPage: page,
            lastPage: 3,
            hasNextPage: page < 3,
          ));
        },
      );

      await cubit.loadFirstPage();
      expect(cubit.state.manga.length, 2);
      expect(cubit.state.currentPage, 1);

      await cubit.loadNextPage();
      expect(cubit.state.manga.length, 4);
      expect(cubit.state.currentPage, 2);
      expect(cubit.state.hasNextPage, isTrue);
      expect(callCount, 2);

      await cubit.close();
    });

    test('loadNextPage does nothing when hasNextPage is false', () async {
      int callCount = 0;
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async {
          callCount++;
          return Right(MangaSearchResult(
            results: [_manga(1)],
            currentPage: 1,
            lastPage: 1,
            hasNextPage: false,
          ));
        },
      );

      await cubit.loadFirstPage();
      expect(callCount, 1);

      await cubit.loadNextPage();
      // Should not have made another call
      expect(callCount, 1);
      expect(cubit.state.manga.length, 1);

      await cubit.close();
    });

    test('loadNextPage does nothing while already loading more', () async {
      int callCount = 0;
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async {
          callCount++;
          // Simulate slow response for page 2
          if (page > 1) await Future.delayed(const Duration(milliseconds: 100));
          return Right(MangaSearchResult(
            results: [_manga(page)],
            currentPage: page,
            lastPage: 5,
            hasNextPage: true,
          ));
        },
      );

      await cubit.loadFirstPage();

      // Fire two loadNextPage calls simultaneously
      final f1 = cubit.loadNextPage();
      final f2 = cubit.loadNextPage();
      await Future.wait([f1, f2]);

      // Only one additional fetch should have been made
      expect(callCount, 2);

      await cubit.close();
    });

    test('loadNextPage handles error without losing existing data', () async {
      int callCount = 0;
      final cubit = PaginatedListCubit(
        fetcher: ({int page = 1}) async {
          callCount++;
          if (page == 1) {
            return Right(MangaSearchResult(
              results: [_manga(1), _manga(2)],
              currentPage: 1,
              lastPage: 3,
              hasNextPage: true,
            ));
          }
          return const Left('Page load failed');
        },
      );

      await cubit.loadFirstPage();
      expect(cubit.state.manga.length, 2);

      await cubit.loadNextPage();
      // Existing data should be preserved
      expect(cubit.state.manga.length, 2);
      expect(cubit.state.status, PaginatedStatus.loaded);
      expect(cubit.state.error, 'Page load failed');

      await cubit.close();
    });
  });
}
