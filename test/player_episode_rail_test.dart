import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/player/presentation/widgets/in_player_episodes_sheet.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_episode_swipe_handle.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_gesture_detector.dart';
import 'package:calium_stream/features/player/presentation/widgets/precision_seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom upward swipe opens once without changing volume', (
    tester,
  ) async {
    var opens = 0;
    var volume = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onVerticalDragUpdate: (_) => volume++,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.black)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PlayerEpisodeSwipeHandle(onOpen: () => opens++),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.drag(
      find.byType(PlayerEpisodeSwipeHandle),
      const Offset(0, -100),
    );
    await tester.pump();
    expect(opens, 1);
    expect(volume, 0);
    await tester.drag(
      find.byType(PlayerEpisodeSwipeHandle),
      const Offset(0, 100),
    );
    expect(opens, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerEpisodeSwipeHandle(isLocked: true, onOpen: () => opens++),
      ),
    );
    await tester.drag(
      find.byType(PlayerEpisodeSwipeHandle),
      const Offset(0, -100),
    );
    expect(opens, 1);
  });

  testWidgets(
    'surface gestures, seek and bottom rail keep separate hit regions',
    (tester) async {
      var opens = 0;
      var brightness = 0;
      var volume = 0;
      final seeks = <Duration>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: PlayerGestureDetector(
                    currentPosition: const Duration(seconds: 50),
                    totalDuration: const Duration(seconds: 100),
                    isLocked: false,
                    onTap: () {},
                    onDoubleTapLeft: (_) {},
                    onDoubleTapRight: (_) {},
                    onDoubleTapCenter: () {},
                    onLongPressStart: () {},
                    onLongPressEnd: () {},
                    onBrightnessChanged: (_) => brightness++,
                    onVolumeChanged: (_) => volume++,
                    child: const ColoredBox(color: Colors.black),
                  ),
                ),
                Positioned(
                  left: 40,
                  right: 40,
                  bottom: 64,
                  child: PrecisionSeekBar(
                    position: const Duration(seconds: 50),
                    duration: const Duration(seconds: 100),
                    onSeek: seeks.add,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PlayerEpisodeSwipeHandle(onOpen: () => opens++),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.drag(find.byType(PrecisionSeekBar), const Offset(100, -80));
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(opens, 0);
      expect(brightness + volume, 0);
      await tester.drag(
        find.byType(PlayerEpisodeSwipeHandle),
        const Offset(0, -100),
      );
      expect(opens, 1);
      expect(brightness + volume, 0);
      final gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(0, -60));
      await gesture.up();
      await tester.pump(const Duration(seconds: 1));
      expect(brightness, greaterThan(0));
      expect(volume, 0);
    },
  );

  const episodes = [
    EpisodeEntity(
      id: '1',
      animeId: 'a',
      episodeNumber: 1,
      seasonNumber: 1,
      title: 'Başlangıç',
    ),
    EpisodeEntity(
      id: '2',
      animeId: 'a',
      episodeNumber: 2,
      seasonNumber: 1,
      title: 'Yolculuk',
    ),
    EpisodeEntity(
      id: '3',
      animeId: 'a',
      episodeNumber: 1,
      seasonNumber: 2,
      title: 'Başka sezon',
    ),
  ];

  testWidgets('rail handles landscape large text and absent covers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 360),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: InPlayerEpisodesSheet(
                episodes: episodes,
                currentSeasonNumber: 1,
                currentEpisodeNumber: 1,
                horizontal: true,
                onEpisodeSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.movie_outlined), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rail filters season, marks selection, switches and closes', (
    tester,
  ) async {
    EpisodeEntity? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => InPlayerEpisodesSheet(
                  episodes: episodes,
                  currentSeasonNumber: 1,
                  currentEpisodeNumber: 1,
                  horizontal: true,
                  onEpisodeSelected: (ep) => selected = ep,
                ),
              ),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Başka sezon'), findsNothing);
    expect(find.text('Oynatılıyor'), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byType(ListView)).scrollDirection,
      Axis.horizontal,
    );
    await tester.tap(find.text('Yolculuk'));
    await tester.pumpAndSettle();
    expect(selected, episodes[1]);
    expect(find.text('Yolculuk'), findsNothing);
    selected = null;
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlangıç'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bölümleri kapat'));
    await tester.pumpAndSettle();
    expect(find.text('Yolculuk'), findsNothing);
  });
}
