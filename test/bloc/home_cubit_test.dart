import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:manga_recommendation_app/bloc/home/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/home/home_state.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';

class MockMangaService extends Mock implements MangaService {}

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

  setUpAll(() async {
    // Use a unique Hive directory to avoid lock conflicts with parallel test files
    Hive.init('build/test_cache/home_cubit');
    await MangaStatusService.init();
  });

  setUp(() {
    mockService = MockMangaService();
  });

  HomeCubit buildCubit() => HomeCubit(mangaService: mockService);

  group('HomeCubit', () {
    test('initial state has all sections loading', () {
      final cubit = buildCubit();
      expect(cubit.state.popularStatus, HomeStatus.loading);
      expect(cubit.state.latestStatus, HomeStatus.loading);
      expect(cubit.state.recommendedStatus, HomeStatus.loading);
      expect(cubit.state.randomStatus, HomeStatus.loading);
      cubit.close();
    });

    test('load populates all sections on success', () async {
      when(() => mockService.getPopular(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(1), _manga(2)]));
      when(() => mockService.getLatestUpdates(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(3)]));
      // getRecommended won't be called when genres are empty (fresh test Hive),
      // so _loadRecommended will emit loaded with empty list.
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(5)]));

      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.popularStatus, HomeStatus.loaded);
      expect(cubit.state.popularManga.length, 2);
      expect(cubit.state.latestStatus, HomeStatus.loaded);
      expect(cubit.state.latestManga.length, 1);
      // Recommended loaded with empty list (no reading history in test)
      expect(cubit.state.recommendedStatus, HomeStatus.loaded);
      expect(cubit.state.recommendedHasHistory, false);
      expect(cubit.state.randomStatus, HomeStatus.loaded);
      expect(cubit.state.randomManga.length, 1);

      await cubit.close();
    });

    test('load sets error status when popular fails', () async {
      when(() => mockService.getPopular(nsfwEnabled: false))
          .thenAnswer((_) async => const Left('Network error'));
      when(() => mockService.getLatestUpdates(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(1)]));
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(2)]));

      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.popularStatus, HomeStatus.error);
      expect(cubit.state.popularError, 'Network error');
      // Other sections should still load
      expect(cubit.state.latestStatus, HomeStatus.loaded);
      expect(cubit.state.randomStatus, HomeStatus.loaded);

      await cubit.close();
    });

    test('load sets error status when latest fails', () async {
      when(() => mockService.getPopular(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(1)]));
      when(() => mockService.getLatestUpdates(nsfwEnabled: false))
          .thenAnswer((_) async => const Left('Server error'));
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(2)]));

      final cubit = buildCubit();
      await cubit.load();

      expect(cubit.state.popularStatus, HomeStatus.loaded);
      expect(cubit.state.latestStatus, HomeStatus.error);
      expect(cubit.state.latestError, 'Server error');
      expect(cubit.state.randomStatus, HomeStatus.loaded);

      await cubit.close();
    });

    test('refreshRandom only reloads random section', () async {
      when(() => mockService.getPopular(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(1)]));
      when(() => mockService.getLatestUpdates(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(2)]));
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(3)]));

      final cubit = buildCubit();
      await cubit.load();

      // Setup a new random response
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(10), _manga(11)]));

      await cubit.refreshRandom();

      // Random should be refreshed
      expect(cubit.state.randomManga.length, 2);
      expect(cubit.state.randomManga.first.malId, 10);
      // Popular should still be the same
      expect(cubit.state.popularManga.length, 1);
      expect(cubit.state.popularManga.first.malId, 1);

      await cubit.close();
    });

    test('refreshRandom sets error when service fails', () async {
      when(() => mockService.getPopular(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(1)]));
      when(() => mockService.getLatestUpdates(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(2)]));
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => Right([_manga(3)]));

      final cubit = buildCubit();
      await cubit.load();
      expect(cubit.state.randomStatus, HomeStatus.loaded);

      // Now fail on refresh
      when(() => mockService.getRandomBatch(nsfwEnabled: false))
          .thenAnswer((_) async => const Left('Timeout'));

      await cubit.refreshRandom();

      expect(cubit.state.randomStatus, HomeStatus.error);
      expect(cubit.state.randomError, 'Timeout');
      // Popular should still be loaded
      expect(cubit.state.popularStatus, HomeStatus.loaded);

      await cubit.close();
    });

    test('load passes nsfwEnabled to service calls', () async {
      when(() => mockService.getPopular(nsfwEnabled: true))
          .thenAnswer((_) async => const Right([]));
      when(() => mockService.getLatestUpdates(nsfwEnabled: true))
          .thenAnswer((_) async => const Right([]));
      when(() => mockService.getRandomBatch(nsfwEnabled: true))
          .thenAnswer((_) async => const Right([]));

      final cubit = buildCubit();
      await cubit.load(nsfwEnabled: true);

      verify(() => mockService.getPopular(nsfwEnabled: true)).called(1);
      verify(() => mockService.getLatestUpdates(nsfwEnabled: true)).called(1);
      verify(() => mockService.getRandomBatch(nsfwEnabled: true)).called(1);

      await cubit.close();
    });
  });
}
