import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Player preferences shared by the settings screen and the player.
///
/// Backed by the `preferences` Hive box opened in `main()`. When the box is
/// not open (e.g. isolated widget tests), reads fall back to defaults and
/// writes are ignored.
class AppPreferences {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  Box<dynamic>? get _box => Hive.isBoxOpen(StorageKeys.preferencesBox)
      ? Hive.box<dynamic>(StorageKeys.preferencesBox)
      : null;

  String get defaultQuality =>
      _read<String>(StorageKeys.preferredQuality, '1080p');

  /// Canonical audio group token: `original`, `tr` or `en`.
  String get defaultAudio =>
      _read<String>(StorageKeys.preferredAudioLanguage, 'original');

  int get subtitleSize => _read<int>(StorageKeys.subtitleSize, 40);

  bool get gestureBrightness =>
      _read<bool>(StorageKeys.gestureBrightness, true);

  bool get gestureVolume => _read<bool>(StorageKeys.gestureVolume, true);

  bool get autoNext => _read<bool>(StorageKeys.autoPlayNext, true);

  bool get autoSkipIntro => _read<bool>(StorageKeys.autoSkipIntro, false);

  bool get autoDownloadNewEpisodes =>
      _read<bool>(StorageKeys.autoDownloadNewEpisodes, false);

  Future<void> setDefaultQuality(String value) =>
      _write(StorageKeys.preferredQuality, value);

  Future<void> setDefaultAudio(String value) =>
      _write(StorageKeys.preferredAudioLanguage, value);

  Future<void> setSubtitleSize(int value) =>
      _write(StorageKeys.subtitleSize, value);

  Future<void> setGestureBrightness(bool value) =>
      _write(StorageKeys.gestureBrightness, value);

  Future<void> setGestureVolume(bool value) =>
      _write(StorageKeys.gestureVolume, value);

  Future<void> setAutoNext(bool value) =>
      _write(StorageKeys.autoPlayNext, value);

  Future<void> setAutoSkipIntro(bool value) =>
      _write(StorageKeys.autoSkipIntro, value);

  Future<void> setAutoDownloadNewEpisodes(bool value) =>
      _write(StorageKeys.autoDownloadNewEpisodes, value);

  T _read<T>(String key, T fallback) {
    final value = _box?.get(key);
    return value is T ? value : fallback;
  }

  Future<void> _write(String key, Object value) async {
    final box = _box;
    if (box != null) await box.put(key, value);
  }
}
