/// Centralized storage key constants for Hive boxes and secure storage.
///
/// All persistent storage keys are defined here to prevent typos and
/// make it easy to audit what data the app persists.
abstract final class StorageKeys {
  // ─── Hive Box Names ──────────────────────────────────────────
  static const String authBox = 'auth_box';
  static const String userDataBox = 'user_data_box';
  static const String watchHistoryBox = 'watch_history_box';
  static const String favoritesBox = 'favorites_box';
  static const String preferencesBox = 'preferences_box';
  static const String downloadTasksBox = 'download_tasks_box';

  // ─── Secure Storage Keys ─────────────────────────────────────
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';

  // ─── User Data Keys ──────────────────────────────────────────
  static const String currentUser = 'current_user';
  static const String userProfile = 'user_profile';

  // ─── Preferences Keys ────────────────────────────────────────
  static const String themeMode = 'theme_mode';
  static const String preferredQuality = 'preferred_quality';
  static const String preferredSubtitleLanguage = 'preferred_subtitle_language';
  static const String autoPlayNext = 'auto_play_next';
  static const String downloadQuality = 'download_quality';
  static const String downloadWifiOnly = 'download_wifi_only';

  // ─── Watch History Keys ──────────────────────────────────────
  static const String lastWatchedPosition = 'last_watched_position';
  static const String continueWatching = 'continue_watching';

  // ─── Download Task Keys ──────────────────────────────────────
  static const String activeDownloads = 'active_downloads';
  static const String completedDownloads = 'completed_downloads';
}
