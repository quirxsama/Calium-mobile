import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dartz/dartz.dart' show Either, Right;
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_theme.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/core/widgets/app_navigation.dart';
import 'package:calium_stream/core/widgets/adaptive_poster_grid.dart';
import 'package:calium_stream/core/widgets/anime_poster_card.dart';
import 'package:calium_stream/features/home/domain/entities/anime_entity.dart';
import 'package:calium_stream/features/home/presentation/widgets/hero_carousel.dart';
import 'package:calium_stream/features/home/presentation/widgets/anime_rail.dart';
import 'package:calium_stream/features/anime_details/domain/entities/anime_detail_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/domain/entities/cast_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_anime_detail_usecase.dart';
import 'package:calium_stream/features/anime_details/domain/usecases/get_cast_usecase.dart';
import 'package:calium_stream/features/anime_details/presentation/views/anime_detail_screen.dart';
import 'package:calium_stream/features/library/presentation/bloc/library_bloc.dart';

const _anime = AnimeEntity(
  id: 'fixture',
  title: 'Shingeki no Kyojin',
  posterUrl: '',
  rating: 9.1,
  genres: ['Aksiyon', 'Macera', 'Dram'],
  synopsis: 'Bir sonraki bölümde hikâye devam ediyor. Bu içerik yerleşim testi verisidir.',
);
const _detail = AnimeDetailEntity(
  id: 'fixture',
  title: 'Shingeki no Kyojin',
  originalTitle: 'Attack on Titan',
  posterUrl: '',
  rating: 9.1,
  year: 2013,
  status: 'Tamamlandı',
  tmdbId: 1,
  genres: ['Aksiyon', 'Macera', 'Dram'],
  synopsis:
      'Hikâyenin, başlığın ve eylemlerin farklı ekran genişliklerindeki yerleşimini doğrulayan örnek metin. '
      'Bu ekran üretim verisi yerine kontrollü test verileri kullanır.',
  seasons: [
    SeasonEntity(seasonNumber: 1, name: '1. Sezon'),
    SeasonEntity(seasonNumber: 2, name: '2. Sezon'),
  ],
);

class _Repository implements AnimeDetailRepository {
  @override
  Future<Either<Failure, AnimeDetailEntity>> getAnimeDetail(String id) async =>
      const Right(_detail);
  @override
  Future<Either<Failure, List<EpisodeEntity>>> getEpisodes({
    required String animeId,
    required int season,
  }) async => Right([
    for (var i = 1; i <= 30; i++)
      EpisodeEntity(
        id: '$i',
        animeId: animeId,
        episodeNumber: i,
        seasonNumber: season,
        title: 'Bölüm $i',
        duration: 1440,
        overview: 'Bölüm açıklaması ve izleme seçenekleri.',
      ),
  ]);
  @override
  Future<Either<Failure, List<CastEntity>>> getCast(String id) async =>
      const Right([
        CastEntity(
          id: 1,
          characterName: 'Eren Yeager',
          voiceActorName: 'Yuki Kaji',
        ),
      ]);
  @override
  Future<Either<Failure, List<AnimeEntity>>> getSimilarAnime(String id) async =>
      const Right([]);
}

class _Library extends Cubit<LibraryState> implements LibraryBloc {
  _Library() : super(const LibraryLoaded());
  @override
  void add(LibraryEvent event) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _previews = bool.fromEnvironment('UI_PREVIEWS');
final _captureKey = GlobalKey();

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.darkTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: RepaintBoundary(key: _captureKey, child: child),
);

Future<void> _capture(WidgetTester tester, String name) async {
  if (!_previews) return;
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await Directory('build/ui-previews')
        .create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadPreviewFonts(WidgetTester tester) async {
  if (!_previews) return;
  await tester.runAsync(() async {
    for (final font in [
      ('Jakarta', '/tmp/opencode/calium-jakarta.ttf'),
      ('Inter', '/tmp/opencode/calium-inter.ttf'),
    ]) {
      if (await File(font.$2).exists()) {
        final loader = FontLoader(font.$1)
          ..addFont(
            File(font.$2)
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    const heading = TextStyle(
      fontFamily: 'Jakarta',
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    );
    const body = TextStyle(
      fontFamily: 'Inter',
      color: AppColors.textSecondary,
      height: 1.4,
    );
    AppTypography.headlineLarge = heading.copyWith(fontSize: 28);
    AppTypography.headlineMedium = heading.copyWith(fontSize: 22);
    AppTypography.titleMedium = heading.copyWith(fontSize: 16);
    AppTypography.titleSmall = heading.copyWith(fontSize: 15);
    AppTypography.bodyLarge = body.copyWith(fontSize: 16);
    AppTypography.bodyMedium = body.copyWith(fontSize: 14);
    AppTypography.bodySmall = body.copyWith(fontSize: 13);
    AppTypography.badgeSmall = body.copyWith(
      fontSize: 11,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );
    AppTypography.caption = body.copyWith(fontSize: 12);
    storage = await Directory.systemTemp.createTemp('calium-ui-');
    Hive.init(storage.path);
    await Hive.openBox('history');
    await Hive.openBox('favorites');
  });
  tearDownAll(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });
  tearDown(() => GetIt.I.reset());

  for (final configuration in [
    ('phone', const Size(360, 800), 1.0),
    ('tablet', const Size(800, 1280), 1.0),
    ('wide', const Size(1280, 800), 1.0),
    ('large-text', const Size(360, 800), 2.0),
    ('wide-large-text', const Size(1280, 800), 2.0),
  ]) {
    testWidgets(
      '${configuration.$1}: navigation and feature fit the available window',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _loadPreviewFonts(tester);
          tester.view.physicalSize = configuration.$2;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var selected = 0;
          await tester.pumpWidget(
            _app(
              StatefulBuilder(
                builder: (context, setState) => AppNavigation(
                  selectedIndex: selected,
                  onDestinationSelected: (value) =>
                      setState(() => selected = value),
                  child: Scaffold(
                    appBar: AppBar(title: const Text('CALIUM')),
                    body: ListView(
                      children: [
                        HeroCarousel(animes: const [_anime, _anime]),
                        AnimeRail(
                          title: 'Senin için',
                          animes: const [_anime, _anime],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              scale: configuration.$3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.byType(
              configuration.$2.width < 600 ? NavigationBar : NavigationRail,
            ),
            findsOneWidget,
          );
          await _capture(tester, 'feature-${configuration.$1}');
          await tester.tap(find.byTooltip('Sonraki anime'));
          await tester.pumpAndSettle();
          expect(
            find.bySemanticsLabel('Öne çıkan anime 2, toplam 2'),
            findsOneWidget,
          );
          await tester.tap(find.text('Keşfet').last);
          await tester.pumpAndSettle();
          expect(selected, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      '${configuration.$1}: poster grid adapts columns and readable titles',
      (tester) async {
        tester.view.physicalSize = configuration.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: AdaptivePosterGrid(
                itemCount: 20,
                itemBuilder: (_, index) => AnimePosterCard(
                  id: '$index',
                  title: 'Uzun bir anime başlığı $index',
                  posterUrl: '',
                  episodeBadge: '12 bölüm',
                  rating: 8.5,
                  onTap: () {},
                ),
              ),
            ),
            scale: configuration.$3,
          ),
        );
        await tester.pumpAndSettle();
        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(
          delegate.crossAxisCount,
          configuration.$2.width < 600 ? 2 : greaterThanOrEqualTo(4),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final size in [const Size(360, 800), const Size(1280, 800)]) {
    testWidgets(
      'detail ${size.width}: overview, episode controls and search remain usable at 2x text',
      (tester) async {
        await _loadPreviewFonts(tester);
        final repository = _Repository();
        GetIt.I.registerSingleton<AnimeDetailRepository>(repository);
        GetIt.I.registerSingleton<GetAnimeDetailUseCase>(
          GetAnimeDetailUseCase(repository: repository),
        );
        GetIt.I.registerSingleton<GetCastUseCase>(
          GetCastUseCase(repository: repository),
        );
        final library = _Library();
        addTearDown(library.close);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          BlocProvider<LibraryBloc>.value(
            value: library,
            child: _app(const AnimeDetailScreen(animeId: 'fixture'), scale: 2),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _capture(tester, 'detail-${size.width.toInt()}');
        if (size.width >= 900) {
          expect(
            tester.getTopLeft(find.text('Bölümler')).dx,
            greaterThan(tester.getTopRight(find.text('İzlemeye başla')).dx),
          );
        }
        final search = find.byType(TextField);
        await tester.ensureVisible(search);
        await tester.enterText(search, 'bulunamayan bölüm');
        await tester.pumpAndSettle();
        expect(
          find.text('Aramanızla eşleşen bölüm bulunamadı.'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text('2. Sezon'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2. Sezon'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, isEmpty);
        expect(find.text('Aramanızla eşleşen bölüm bulunamadı.'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
