import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelEpisodesId = 'calium_episodes';
  static const String _channelEpisodesName = 'Yeni Bölüm Bildirimleri';
  static const String _channelSocialId = 'calium_social';
  static const String _channelSocialName = 'Sosyal Bildirimler';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    // Create high-importance Android Notification Channels
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelEpisodesId,
          _channelEpisodesName,
          description: 'Favori animelerin yeni bölümleri yayınlandığında bildirim gönderir.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelSocialId,
          _channelSocialName,
          description: 'Takipçi ve sosyal aktiviteler için bildirim gönderir.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    // Request notification permission
    await requestPermission();

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ Notification permission request error: $e');
      return false;
    }
  }

  Future<void> showEpisodeNotification({
    required int id,
    required String animeTitle,
    required String episodeNumber,
    String? animeId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelEpisodesId,
        _channelEpisodesName,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        '🔥 Yeni Bölüm Yayında!',
        '$animeTitle - Bölüm $episodeNumber yayına girdi. Hemen izle!',
        details,
        payload: animeId != null ? 'anime:$animeId' : null,
      );
    } catch (e) {
      debugPrint('⚠️ Show notification error: $e');
    }
  }

  Future<void> showSocialNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelSocialId,
        _channelSocialName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('⚠️ Show social notification error: $e');
    }
  }
}
