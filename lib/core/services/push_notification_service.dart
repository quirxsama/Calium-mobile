import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:calium_stream/core/services/notification_service.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.initializeFirebase();
}

/// Registers the Android FCM token with the Calium backend and renders
/// foreground pushes through the local notification service.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  SyncRemoteDataSource? _remoteDataSource;
  String? _installationId;
  bool _firebaseReady = false;
  bool _initialized = false;
  bool _registered = false;

  /// True once a token was registered for the signed-in user. The periodic
  /// sync uses this to avoid duplicating FCM notifications locally.
  bool get isRegistered => _registered;

  Future<void> init({required SyncRemoteDataSource remoteDataSource}) async {
    if (_initialized) return;
    _initialized = true;
    _remoteDataSource = remoteDataSource;

    _firebaseReady = await initializeFirebase();
    if (!_firebaseReady) return;

    _installationId = await _loadInstallationId();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    // Classic FCM registration tokens are still required by the backend's
    // sendEachForMulticast calls; the replacement emits an installation ID.
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
    );

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {}

    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onMessageOpened(initialMessage);
        });
      }
    } catch (_) {}

    AccountSession.instance.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  /// Builds Firebase from the public client values bundled in `.env`.
  /// Returns false when the app has not been configured for FCM yet.
  static Future<bool> initializeFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
    } catch (_) {}

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    final apiKey = dotenv.env['FIREBASE_ANDROID_API_KEY']?.trim() ?? '';
    final appId = dotenv.env['FIREBASE_ANDROID_APP_ID']?.trim() ?? '';
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim() ?? '';
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        senderId.isEmpty ||
        projectId.isEmpty) {
      return false;
    }

    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: senderId,
          projectId: projectId,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ Firebase initialization failed: $e');
      return false;
    }
  }

  void _onSessionChanged() {
    final session = AccountSession.instance;
    if (session.ready && session.userId != null) {
      unawaited(_registerToken());
    } else if (_registered) {
      unawaited(unregister());
    }
  }

  /// Retries a failed initial registration on the next sync tick.
  Future<void> ensureRegistered() async {
    if (_registered) return;
    await _registerToken();
  }

  Future<void> _registerToken([String? token]) async {
    if (!_firebaseReady ||
        _remoteDataSource == null ||
        _installationId == null) {
      return;
    }
    final session = AccountSession.instance;
    if (!session.ready || session.userId == null) return;
    final generation = session.generation;

    try {
      final value =
          token ??
          // ignore: deprecated_member_use
          await FirebaseMessaging.instance.getToken();
      if (value == null || value.isEmpty) return;
      if (session.generation != generation) return;
      final registered = await _remoteDataSource!.registerDeviceToken(
        token: value,
        installationId: _installationId!,
      );
      if (session.generation == generation) _registered = registered;
    } catch (e) {
      if (session.generation == generation) _registered = false;
      debugPrint('⚠️ FCM token registration failed: $e');
    }
  }

  Future<void> unregister() async {
    final remote = _remoteDataSource;
    final installationId = _installationId;
    if (remote != null &&
        installationId != null &&
        AccountSession.instance.userId != null) {
      try {
        await remote
            .unregisterDeviceToken(installationId: installationId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    _registered = false;
    try {
      await FirebaseMessaging.instance
          .deleteToken(); // ignore: deprecated_member_use
    } catch (_) {}
  }

  Future<String> _loadInstallationId() async {
    if (Hive.isBoxOpen(StorageKeys.preferencesBox)) {
      final box = Hive.box(StorageKeys.preferencesBox);
      final existing = box.get(StorageKeys.pushInstallationId);
      if (existing is String && existing.isNotEmpty) return existing;
    }

    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    if (Hive.isBoxOpen(StorageKeys.preferencesBox)) {
      await Hive.box(StorageKeys.preferencesBox)
          .put(StorageKeys.pushInstallationId, id);
    }
    return id;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final animeId = data['animeId']?.toString() ?? '';

    String? payload;
    String? dedupeKey;
    if (type == 'new_episode' && animeId.isNotEmpty) {
      final season = data['seasonNumber']?.toString() ?? '1';
      final episode = data['episodeNumber']?.toString() ?? '1';
      dedupeKey = 'push_notified_ep_${animeId}_s${season}_$episode';
      payload = 'anime:$animeId';
    } else {
      final notificationId = data['notificationId']?.toString() ?? '';
      if (notificationId.isNotEmpty) {
        dedupeKey = 'push_notified_soc_$notificationId';
      }
      payload = type.isNotEmpty ? 'social:$type' : null;
    }

    if (dedupeKey != null && !await _claim(dedupeKey)) return;

    final id =
        message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(100000);
    if (type == 'new_episode' && animeId.isNotEmpty) {
      await NotificationService.instance.showPushNotification(
        id: id,
        title: notification.title ?? 'Calium',
        body: notification.body ?? '',
        payload: payload,
      );
    } else {
      await NotificationService.instance.showSocialNotification(
        id: id,
        title: notification.title ?? 'Calium',
        body: notification.body ?? '',
        payload: payload,
      );
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString() ?? '';
    final animeId = data['animeId']?.toString() ?? '';
    if (type == 'new_episode' && animeId.isNotEmpty) {
      NotificationService.handlePayload('anime:$animeId');
    } else if (type.isNotEmpty) {
      NotificationService.handlePayload('social:$type');
    }
  }

  Future<bool> _claim(String key) async {
    if (!Hive.isBoxOpen(StorageKeys.preferencesBox)) return true;
    final box = Hive.box(StorageKeys.preferencesBox);
    if (box.containsKey(key)) return false;
    await box.put(key, DateTime.now().millisecondsSinceEpoch);
    return true;
  }
}
