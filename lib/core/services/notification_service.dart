import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:calium_stream/app/router.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelEpisodesId = 'anime_episodes';
  static const String _channelEpisodesName = 'Yeni Bölüm Bildirimleri';
  static const String _channelSocialId = 'calium_social';
  static const String _channelSocialName = 'Sosyal Bildirimler';
  static const String _channelDownloadsId = 'calium_downloads';
  static const String _channelDownloadsName = 'İndirme Bildirimleri';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
        handlePayload(response.payload);
      },
    );

    // Create high-importance Android Notification Channels
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

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

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelDownloadsId,
          _channelDownloadsName,
          description: 'Bölüm indirme ilerlemesi ve tamamlanma bildirimleri.',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );
    }

    // Request notification permission
    await requestPermission();

    final launchDetails = await _notificationsPlugin
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handlePayload(payload);
        });
      }
    }

    _initialized = true;
  }

  static void handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      if (payload.startsWith('anime:')) {
        final animeId = payload.substring('anime:'.length);
        AppRouter.router.push('/anime/$animeId');
      } else if (payload.startsWith('watch:')) {
        AppRouter.router.push(payload.substring('watch:'.length));
      } else if (payload.startsWith('social:')) {
        AppRouter.router.push('/social');
      } else if (payload.startsWith('/')) {
        AppRouter.router.push(payload);
      }
    } catch (e) {
      debugPrint('⚠️ Notification navigation error: $e');
    }
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
    String? seasonNumber,
    String? animeId,
  }) async {
    final seasonPrefix =
        seasonNumber != null && seasonNumber.isNotEmpty && seasonNumber != '1'
        ? 'Sezon $seasonNumber '
        : '';
    await showPushNotification(
      id: id,
      title: '🔥 Yeni Bölüm: $animeTitle',
      body:
          '$animeTitle - ${seasonPrefix}Bölüm $episodeNumber yayında. Hemen izle!',
      payload: animeId != null ? 'anime:$animeId' : null,
    );
  }

  Future<void> showPushNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelEpisodesId,
        _channelEpisodesName,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('⚠️ Show push notification error: $e');
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

  Future<void> showDownloadProgressNotification({
    required int id,
    required String animeTitle,
    required String episodeLabel,
    required int progressPercent,
    required String speedText,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelDownloadsId,
        _channelDownloadsName,
        importance: Importance.low,
        priority: Priority.low,
        showWhen: false,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent.clamp(0, 100),
        icon: '@mipmap/ic_launcher',
      );

      final details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        '⬇️ İndiriliyor: $animeTitle',
        '$episodeLabel • %$progressPercent ($speedText)',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ Show download progress notification error: $e');
    }
  }

  Future<void> showDownloadCompletedNotification({
    required int id,
    required String animeTitle,
    required String episodeLabel,
  }) async {
    if (!_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelDownloadsId,
        _channelDownloadsName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        onlyAlertOnce: false,
        ongoing: false,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        '✅ İndirme Tamamlandı',
        '$animeTitle - $episodeLabel çevrimdışı izlemeye hazır.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ Show download completed notification error: $e');
    }
  }

  Future<void> showDownloadFailedNotification({
    required int id,
    required String animeTitle,
    required String episodeLabel,
  }) async {
    if (!_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelDownloadsId,
        _channelDownloadsName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        onlyAlertOnce: false,
        ongoing: false,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        '❌ İndirme Başarısız',
        '$animeTitle - $episodeLabel indirilemedi. Ayrıntılar ve yeniden deneme için İndirmeler ekranını açın.',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ Show download failed notification error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('⚠️ Cancel notification error: $e');
    }
  }
}
