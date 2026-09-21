import 'dart:async';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/domain/entities/home_feed_entity.dart';
import 'package:calium_stream/features/home/domain/usecases/get_home_feed_usecase.dart';
import 'package:calium_stream/features/home/presentation/bloc/home_bloc.dart';
import 'package:calium_stream/features/home/presentation/views/home_screen.dart';
import 'package:calium_stream/features/library/domain/entities/favorite_entity.dart';
import 'package:calium_stream/features/library/domain/entities/history_entity.dart';
import 'package:calium_stream/features/library/domain/repositories/library_repository.dart';
import 'package:calium_stream/features/library/domain/usecases/get_favorites_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/get_history_usecase.dart';
import 'package:calium_stream/features/library/domain/usecases/toggle_favorite_usecase.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';
import 'package:calium_stream/features/library/presentation/views/library_screen.dart';
import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class _Feed implements GetHomeFeedUseCase {
  final requests = <Completer<Either<Failure, HomeFeedEntity>>>[];
  @override
  Future<Either<Failure, HomeFeedEntity>> call() {
    final request = Completer<Either<Failure, HomeFeedEntity>>();
    requests.add(request);
    return request.future;
  }
}

class _Details implements GetAnimeDetailUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Library implements LibraryRepository {
  Either<Failure, List<FavoriteEntity>> favorites = const Right([]);
  Either<Failure, List<HistoryEntity>> history = const Right([]);
  @override
  Future<Either<Failure, List<FavoriteEntity>>> getFavorites() async =>
      favorites;
  @override
  Future<Either<Failure, List<HistoryEntity>>> getHistory() async => history;
  @override
  Future<Either<Failure, void>> clearHistory() async =>
      const Left(CacheFailure(message: 'disk unavailable'));
  @override
  Future<Either<Failure, void>> removeHistoryItem(String id) async =>
      const Left(CacheFailure(message: 'disk unavailable'));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth extends Cubit<AuthState> implements AuthBloc {
  _Auth() : super(Unauthenticated());
  @override
  void add(AuthEvent event) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LibraryBloc _libraryBloc(_Library repository) => LibraryBloc(
  getFavoritesUseCase: GetFavoritesUseCase(repository: repository),
  getHistoryUseCase: GetHistoryUseCase(repository: repository),
  toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
  libraryRepository: repository,
);

Future<LibraryLoaded> loadLibrary(LibraryBloc bloc) async {
  final result = bloc.stream
      .where((state) => state is LibraryLoaded && !state.isRefreshing)
      .cast<LibraryLoaded>()
      .first;
  bloc.add(LoadLibraryRequested());
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.testLoad(fileInput: '');
  // Keep these tests independent of external font downloads.
  AppTypography.headlineLarge = const TextStyle(fontSize: 24);
  AppTypography.headlineMedium = const TextStyle(fontSize: 20);
  AppTypography.titleMedium = const TextStyle(fontSize: 16);
  AppTypography.titleSmall = const TextStyle(fontSize: 14);
  AppTypography.bodySmall = const TextStyle(fontSize: 12);
  AppTypography.caption = const TextStyle(fontSize: 10);

  test(
    'home refresh failure preserves loaded content and ends refresh',
    () async {
      final feed = _Feed();
      final bloc = HomeBloc(
        getHomeFeed: feed,
        getAnimeDetailUseCase: _Details(),
      );
      addTearDown(bloc.close);
      final loaded = bloc.stream.firstWhere((s) => s is HomeLoaded);
      bloc.add(LoadHomeFeedRequested());
      await Future<void>.delayed(Duration.zero);
      feed.requests.single.complete(
        const Right(
          HomeFeedEntity(
            trending: [],
            topAiring: [],
            seasonal: [],
            movies: [AnimeEntity(id: 'film', title: 'Film', posterUrl: '')],
          ),
        ),
      );
      await loaded;
      final failed = bloc.stream.firstWhere(
        (s) => s is HomeLoaded && s.refreshError.isNotEmpty,
      );
      bloc.add(RefreshHomeFeedRequested());
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as HomeLoaded).isRefreshing, isTrue);
      feed.requests.last.complete(
        const Left(NetworkFailure(message: 'offline')),
      );
      final state = await failed as HomeLoaded;
      expect(state.movies.single.id, 'film');
      expect(state.isRefreshing, isFalse);
    },
  );

  test(
    'library read failure is not presented as an empty successful collection',
    () async {
      final repository = _Library()
        ..favorites = const Left(CacheFailure(message: 'unavailable'));
      final bloc = _libraryBloc(repository);
      addTearDown(bloc.close);
      final state = await loadLibrary(bloc);
      expect(state.favoritesError, isNotEmpty);
      expect(state.historyError, isEmpty);
    },
  );

  test('failed history removal keeps the original item visible', () async {
    final item = HistoryEntity(
      animeId: 'a',
      animeName: 'Anime',
      posterUrl: '',
      episodeId: '1',
      episodeName: 'Bölüm',
      seasonNumber: 1,
      episodeNumber: 1,
      progress: .5,
      duration: 1200,
      updatedAt: DateTime(2026),
    );
    final repository = _Library()..history = Right([item]);
    final bloc = _libraryBloc(repository);
    addTearDown(bloc.close);
    await loadLibrary(bloc);
    final failed = bloc.stream.firstWhere(
      (s) => s is LibraryLoaded && s.errorMessage.isNotEmpty,
    );
    bloc.add(const RemoveHistoryItemRequested(animeId: 'a'));
    final state = await failed as LibraryLoaded;
    expect(state.history, [item]);
  });

  for (final empty in [false, true]) {
    testWidgets(
      empty
          ? 'empty home is not labelled offline'
          : 'server error is not labelled offline',
      (tester) async {
        final feed = _Feed();
        final bloc = HomeBloc(
          getHomeFeed: feed,
          getAnimeDetailUseCase: _Details(),
        );
        addTearDown(bloc.close);
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const HomeScreen(),
            ),
          ),
        );
        bloc.add(LoadHomeFeedRequested());
        await tester.pump();
        feed.requests.single.complete(
          empty
              ? const Right(
                  HomeFeedEntity(trending: [], topAiring: [], seasonal: []),
                )
              : const Left(ServerFailure(message: '503')),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            empty ? 'Henüz içerik bulunamadı' : 'Ana sayfa yüklenemedi',
          ),
          findsOneWidget,
        );
        expect(find.text('Çevrimdışı Moddasınız'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('library error has a reachable retry action with enlarged text', (
    tester,
  ) async {
    final repository = _Library()
      ..favorites = const Left(CacheFailure(message: 'unavailable'));
    final bloc = _libraryBloc(repository);
    final auth = _Auth();
    addTearDown(bloc.close);
    addTearDown(auth.close);
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<LibraryBloc>.value(value: bloc),
          BlocProvider<AuthBloc>.value(value: auth),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoriler'));
    await tester.pumpAndSettle();
    expect(find.text('İçerik yüklenemedi'), findsOneWidget);
    expect(find.text('Henüz favori eklemedin'), findsNothing);
    final retry = find.text('Yeniden dene');
    await tester.ensureVisible(retry);
    expect(retry.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    repository.favorites = const Right([]);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Henüz favori eklemedin'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
