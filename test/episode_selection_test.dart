import 'dart:io';

import 'package:calium_stream/core/services/account_session.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/presentation/widgets/episode_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _episodes = [
  EpisodeEntity(
    id: '1',
    animeId: 'fixture',
    episodeNumber: 1,
    seasonNumber: 1,
    title: 'Bölüm 1',
    duration: 1440,
  ),
  EpisodeEntity(
    id: '2',
    animeId: 'fixture',
    episodeNumber: 2,
    seasonNumber: 1,
    title: 'Bölüm 2',
    duration: 1440,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;

  setUp(() async {
    AppTypography.titleSmall = const TextStyle(fontSize: 15);
    AppTypography.bodyMedium = const TextStyle(fontSize: 14);
    AppTypography.bodySmall = const TextStyle(fontSize: 13);
    AppTypography.caption = const TextStyle(fontSize: 12);
    storage = await Directory.systemTemp.createTemp('calium-selection-');
    Hive.init(storage.path);
    await AccountSession.instance.activate(
      null,
      AccountSession.instance.generation,
    );
  });

  tearDown(() async {
    await Hive.close();
    await storage.delete(recursive: true);
  });

  testWidgets('selecting episodes updates the bulk download count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: EpisodeListWidget(
              animeId: 'fixture',
              animeTitle: 'Fixture',
              seasons: const [],
              episodes: _episodes,
              selectedSeason: 1,
              onSeasonChanged: (_) {},
              onEpisodeTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Toplu indirme seç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('0 bölüm seçildi'), findsOneWidget);
    final bulkButton = find.widgetWithText(
      FilledButton,
      'Seçilenleri indir (0)',
    );
    expect(tester.widget<FilledButton>(bulkButton).onPressed, isNull);

    final checkbox = find.byType(Checkbox).first;
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(find.text('1 bölüm seçildi'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Tümünü seç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tümünü seç'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('2 bölüm seçildi'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Seçilenleri indir (2)'),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Seçimi kaldır'));
    await tester.pumpAndSettle();
    expect(find.text('0 bölüm seçildi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
