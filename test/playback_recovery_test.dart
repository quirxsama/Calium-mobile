import 'dart:async';

import 'package:calium_stream/features/player/presentation/playback_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recovery is bounded even when reopening throws', () async {
    final recovery = PlaybackRecovery();
    final attempts = <int>[];
    expect(
      await recovery.run((attempt) async {
        attempts.add(attempt);
        throw StateError('disconnected');
      }),
      isFalse,
    );
    expect(attempts, [1, 2, 3]);
    expect(recovery.isRunning, isFalse);
  });

  test('a successful playback confirmation ends recovery', () async {
    final attempts = <int>[];
    expect(
      await PlaybackRecovery().run((attempt) async {
        attempts.add(attempt);
        return attempt == 2;
      }),
      isTrue,
    );
    expect(attempts, [1, 2]);
  });

  test('switching media invalidates an in-flight recovery', () async {
    final recovery = PlaybackRecovery();
    final oldAttempt = Completer<bool>();
    final old = recovery.run((_) => oldAttempt.future);
    recovery.cancel();
    final currentAttempt = Completer<bool>();
    final current = recovery.run((_) => currentAttempt.future);
    oldAttempt.complete(true);
    expect(await old, isFalse);
    expect(recovery.isRunning, isTrue);
    currentAttempt.complete(true);
    expect(await current, isTrue);
  });
}
