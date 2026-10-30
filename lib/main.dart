import 'package:flutter/material.dart';
import 'package:calium_stream/core/services/account_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'package:calium_stream/app/app.dart';
import 'package:calium_stream/app/observer.dart';
import 'package:calium_stream/core/constants/storage_keys.dart';
import 'package:calium_stream/injection_container.dart';

import 'package:calium_stream/core/services/app_update_service.dart';
import 'package:calium_stream/core/services/notification_service.dart';
import 'package:calium_stream/core/services/push_notification_service.dart';
import 'package:calium_stream/core/services/sync_remote_datasource.dart';
import 'package:calium_stream/core/services/sync_service.dart';
import 'package:calium_stream/core/services/tracking_service.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback if .env fails to load
  }

  // Optimize image cache limits to prevent frame drops and high RAM usage
  PaintingBinding.instance.imageCache.maximumSize = 250;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 << 20; // 120 MB

  // Initialize media_kit for hardware-accelerated video playback
  MediaKit.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes for offline data
  await AccountSession.instance.activate(
    null,
    AccountSession.instance.generation,
  );
  await Hive.openBox(StorageKeys.preferencesBox);

  // Initialize download service and restore offline download queue
  await DownloadService.instance.init();

  // Initialize AniList & MyAnimeList tracking service

  // Initialize notifications and request permissions
  await NotificationService.instance.init();

  // Register all dependencies via GetIt
  await initDependencies();
  await TrackingService.instance.init();

  // Register the FCM token once the user session is available
  await PushNotificationService.instance.init(
    remoteDataSource: sl<SyncRemoteDataSource>(),
  );

  // Start background realtime sync engine
  sl<SyncService>().start();

  // Set up global BLoC observer for debugging
  Bloc.observer = AppBlocObserver();

  // Check the Calium APK endpoint once per launch after the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(seconds: 1), () {
      AppUpdateService.instance.checkForUpdate();
    });
  });

  runApp(const CaliumApp());
}
