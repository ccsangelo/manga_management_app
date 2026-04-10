import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:manga_recommendation_app/bloc/search/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search/search_event.dart';
import 'package:manga_recommendation_app/bloc/search/search_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/models/search_result/manga_search_result.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';

class MockMangaService extends Mock implements MangaService {}

class MockStorage extends Mock implements Storage {}

Manga _manga(int id) => Manga(
      malId: id,
      title: 'Manga $id',
      genres: [],
      themes: [],
      demographics: [],
      magazines: [],
    );

void main() {
  late MockMangaService mockService;
  late MockStorage mockStorage;

  setUpAll(() {
    mockStorage = MockStorage();
    when(() => mockStorage.read(any())).thenReturn(null);
    when(() => mockStorage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => mockStorage.delete(any())).thenAnswer((_) async {});
    when(() => mockStorage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = mockStorage;
  });

  setUp(() {
    mockService = MockMangaService();
  });

  SearchBloc buildBloc() => SearchBloc(mangaService: mockService);

  group('SearchBloc', () {
    test('initial state is SearchInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<SearchInitial>());
      bloc.close();
    });

    test('emits [SearchLoading, SearchSuccess] on successful search', () {
      final manga = [_manga(1), _manga(2)];
      when(() => mockService.searchManga(
            'naruto',
            page: 1,
            nsfwEnabled: false,
            sortDescending: true,
            orMode: false,
          )).thenAnswer((_) async => Right(
            MangaSearchResult(
              results: manga,
              currentPage: 1,
              lastPage: 5,
              hasNextPage: true,
            ),
          ));

      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchLoading>(),
          isA<SearchSuccess>()
              .having((s) => s.results.length, 'results length', 2)
              .having((s) => s.keywords, 'keywords', 'naruto')
              .having((s) => s.hasNextPage, 'hasNextPage', true)
              .having((s) => s.currentPage, 'currentPage', 1),
        ]),
      );

      bloc.add(SearchRequested('naruto'));
    });

    test('emits [SearchLoading, SearchFailure] on failed search', () {
      when(() => mockService.searchManga(
            'test',
            page: 1,
            nsfwEnabled: false,
            sortDescending: true,
            orMode: false,
          )).thenAnswer((_) async => const Left('API error'));

      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchLoading>(),
          isA<SearchFailure>()
              .having((s) => s.message, 'message', 'API error'),
        ]),
      );

      bloc.add(SearchRequested('test'));
    });

    test('LoadMoreResults appends results and updates page', () async {
      when(() => mockService.searchManga(
            'naruto',
            page: 1,
            nsfwEnabled: false,
            sortDescending: true,
            orMode: false,
          )).thenAnswer((_) async => Right(
            MangaSearchResult(
              results: [_manga(1)],
              currentPage: 1,
              lastPage: 3,
              hasNextPage: true,
            ),
          ));
      when(() => mockService.searchManga(
            'naruto',
            page: 2,
            nsfwEnabled: false,
            sortDescending: true,
            orMode: false,
          )).thenAnswer((_) async => Right(
            MangaSearchResult(
              results: [_manga(2)],
              currentPage: 2,
              lastPage: 3,
              hasNextPage: true,
            ),
          ));

      final bloc = buildBloc();

      // First perform the initial search
      bloc.add(SearchRequested('naruto'));
      // Wait for it to complete
      await expectLater(
        bloc.stream,
        emitsThrough(isA<SearchSuccess>()),
      );

      // Now load more
      bloc.add(LoadMoreResults());

      // Expect: SearchSuccess with isLoadingMore=true, then SearchSuccess with more results
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchSuccess>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', true),
          isA<SearchSuccess>()
              .having((s) => s.results.length, 'results length', 2)
              .having((s) => s.currentPage, 'currentPage', 2)
              .having((s) => s.isLoadingMore, 'isLoadingMore', false),
        ]),
      );

      bloc.close();
    });

    test('LoadMoreResults does nothing when not in SearchSuccess state', () async {
      final bloc = buildBloc();

      // In initial state, LoadMoreResults should do nothing
      bloc.add(LoadMoreResults());
      // Give it time to process
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<SearchInitial>());

      bloc.close();
    });

    test('passes nsfwEnabled and orMode to service', () {
      when(() => mockService.searchManga(
            'test',
            page: 1,
            nsfwEnabled: true,
            sortDescending: false,
            orMode: true,
          )).thenAnswer((_) async => Right(
            MangaSearchResult(
              results: [_manga(1)],
              currentPage: 1,
              lastPage: 1,
              hasNextPage: false,
            ),
          ));

      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<SearchLoading>(),
          isA<SearchSuccess>()
              .having((s) => s.nsfwEnabled, 'nsfwEnabled', true)
              .having((s) => s.orMode, 'orMode', true),
        ]),
      );

      bloc.add(SearchRequested('test',
          nsfwEnabled: true, sortDescending: false, orMode: true));
    });
  });
}
