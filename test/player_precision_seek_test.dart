import 'package:calium_stream/features/player/presentation/widgets/precision_seek_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seek clamp bounds negative, overshoot and unknown duration', () {
    expect(
      clampPlayerSeek(
        const Duration(seconds: -10),
        const Duration(seconds: 100),
      ),
      Duration.zero,
    );
    expect(
      clampPlayerSeek(
        const Duration(seconds: 110),
        const Duration(seconds: 100),
      ),
      const Duration(seconds: 100),
    );
    expect(
      clampPlayerSeek(const Duration(seconds: 10), Duration.zero),
      Duration.zero,
    );
    expect(
      clampPlayerSeek(
        const Duration(milliseconds: 1234),
        const Duration(seconds: 100),
      ),
      const Duration(milliseconds: 1234),
    );
  });
  Widget bar(
    List<Duration> seeks, {
    Duration duration = const Duration(seconds: 100),
    bool enabled = true,
    VoidCallback? onStart,
    VoidCallback? onEnd,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: PrecisionSeekBar(
              position: const Duration(seconds: 50),
              duration: duration,
              enabled: enabled,
              onSeek: seeks.add,
              onSeekStart: onStart,
              onSeekEnd: onEnd,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'upward scrub previews finer movement and seeks only on release',
    (tester) async {
      final seeks = <Duration>[];
      var starts = 0;
      var ends = 0;
      await tester.pumpWidget(
        bar(seeks, onStart: () => starts++, onEnd: () => ends++),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PrecisionSeekBar)),
      );
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(find.textContaining('Hassas sarma'), findsOneWidget);
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      expect(seeks, isEmpty);
      expect(starts, 1);
      await gesture.up();
      await tester.pump();
      expect(seeks.single.inMilliseconds, inInclusiveRange(52000, 54000));
      expect(ends, 1);
    },
  );

  testWidgets('normal scrub clamps both ends and cancel never seeks', (
    tester,
  ) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(bar(seeks));
    final center = tester.getCenter(find.byType(PrecisionSeekBar));
    var gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(700, 0));
    await gesture.up();
    await tester.pump();
    expect(seeks.single, const Duration(seconds: 100));
    gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(-700, 0));
    await gesture.up();
    await tester.pump();
    expect(seeks.last, Duration.zero);
    gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, -60));
    await gesture.cancel();
    await tester.pump();
    expect(seeks.length, 2);
    expect(find.textContaining('Hassas sarma'), findsNothing);
  });

  testWidgets('accessible seek actions step and clamp playback time', (
    tester,
  ) async {
    final seeks = <Duration>[];
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(bar(seeks));
    final node = tester.getSemantics(find.bySemanticsLabel('Oynatma konumu'));
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.increase,
    );
    expect(seeks.single, const Duration(seconds: 55));
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.decrease,
    );
    expect(seeks.last, const Duration(seconds: 45));
    semantics.dispose();
  });

  testWidgets('unknown duration and locked controls ignore seeking', (
    tester,
  ) async {
    final seeks = <Duration>[];
    for (final widget in [
      bar(seeks, duration: Duration.zero),
      bar(seeks, enabled: false),
    ]) {
      await tester.pumpWidget(widget);
      await tester.drag(find.byType(PrecisionSeekBar), const Offset(100, -60));
      await tester.tap(find.byType(PrecisionSeekBar));
      await tester.pump();
    }
    expect(seeks, isEmpty);
  });

  testWidgets('scrubbing triggers onPreviewSeek continuously during movement', (
    tester,
  ) async {
    final previewSeeks = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: PrecisionSeekBar(
                position: const Duration(seconds: 50),
                duration: const Duration(seconds: 100),
                onSeek: (_) {},
                onPreviewSeek: previewSeeks.add,
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PrecisionSeekBar)),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(previewSeeks, isNotEmpty);
    await gesture.up();
  });
}
