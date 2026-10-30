import 'dart:io';

import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/services/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('calium_prefs_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('defaults are safe when the preferences box is closed', () {
    final prefs = AppPreferences.instance;

    expect(prefs.defaultQuality, '1080p');
    expect(prefs.defaultAudio, 'original');
    expect(prefs.subtitleSize, 40);
    expect(prefs.gestureBrightness, isTrue);
    expect(prefs.gestureVolume, isTrue);
    expect(prefs.autoNext, isTrue);
    expect(prefs.autoSkipIntro, isFalse);
    expect(prefs.autoDownloadNewEpisodes, isFalse);
  });

  test('player preferences persist across box reopen', () async {
    final prefs = AppPreferences.instance;
    var box = await Hive.openBox<dynamic>(StorageKeys.preferencesBox);

    await prefs.setDefaultQuality('720p');
    await prefs.setDefaultAudio('tr');
    await prefs.setSubtitleSize(52);
    await prefs.setGestureBrightness(false);
    await prefs.setGestureVolume(false);
    await prefs.setAutoNext(false);
    await prefs.setAutoSkipIntro(true);
    await prefs.setAutoDownloadNewEpisodes(true);

    await box.close();
    box = await Hive.openBox<dynamic>(StorageKeys.preferencesBox);

    expect(prefs.defaultQuality, '720p');
    expect(prefs.defaultAudio, 'tr');
    expect(prefs.subtitleSize, 52);
    expect(prefs.gestureBrightness, isFalse);
    expect(prefs.gestureVolume, isFalse);
    expect(prefs.autoNext, isFalse);
    expect(prefs.autoSkipIntro, isTrue);
    expect(prefs.autoDownloadNewEpisodes, isTrue);

    await box.close();
  });
}
