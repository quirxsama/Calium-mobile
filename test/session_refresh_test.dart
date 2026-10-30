import 'dart:io';

import 'package:calium_stream/app/session_data_refresher.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('restoring the stored session triggers an account data refresh',
      (tester) async {
    // Hive file I/O has to run outside the fake-async zone.
    final directory = await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('calium-session-test');
      Hive.init(dir.path);
      await AccountSession.instance.activate(
        null,
        AccountSession.instance.generation,
      );
      return dir;
    });

    final calls = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SessionDataRefresher(
          onSessionChanged: calls.add,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    expect(calls, isEmpty);

    await tester.runAsync(
      () => AccountSession.instance.activate(
        'user-1',
        AccountSession.instance.generation,
      ),
    );
    await tester.pump();

    expect(calls, ['user-1']);

    // Re-activating the same session must not reload the data again.
    await tester.runAsync(
      () => AccountSession.instance.activate(
        'user-1',
        AccountSession.instance.generation,
      ),
    );
    await tester.pump();

    expect(calls, ['user-1']);

    await tester.runAsync(() async {
      await Hive.close();
      await directory?.delete(recursive: true);
    });
  });
}
