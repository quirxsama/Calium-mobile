import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:calium_stream/app/router.dart';
import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';

/// Checks the Calium APK endpoint once per launch and installs newer builds.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.caliumBackendUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  bool _checking = false;
  bool _shownThisLaunch = false;

  static bool isUpdateAvailable({
    required int remoteCode,
    required int currentCode,
  }) => remoteCode > 0 && remoteCode > currentCode;

  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid || _checking || _shownThisLaunch) return;
    _checking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;

      final response = await _dio.get<Map<String, dynamic>>('/api/apk/latest');
      final release = response.data?['release'];
      if (release is! Map) return;

      final data = Map<String, dynamic>.from(release);
      final remoteCode = (data['versionCode'] as num?)?.toInt() ?? 0;
      if (!isUpdateAvailable(
        remoteCode: remoteCode,
        currentCode: currentCode,
      )) {
        return;
      }

      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      _shownThisLaunch = true;
      await _showUpdateDialog(context, data);
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
    } finally {
      _checking = false;
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> release,
  ) async {
    final version = release['version']?.toString() ?? '';
    final notes = release['notes']?.toString().trim() ?? '';
    final fileSize = (release['fileSize'] as num?)?.toInt() ?? 0;

    final install = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Yeni Sürüm Mevcut',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calium $version yayında.',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  notes,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
              if (fileSize > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Boyut: ${_formatBytes(fileSize)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Daha Sonra'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (install == true && context.mounted) {
      await _downloadAndInstall(context, release);
    }
  }

  Future<void> _downloadAndInstall(
    BuildContext context,
    Map<String, dynamic> release,
  ) async {
    final progress = ValueNotifier<double>(0);
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Güncelleme indiriliyor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: value > 0 ? value.clamp(0, 1) : null,
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  value > 0 ? '%${(value * 100).round()}' : 'Hazırlanıyor…',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/calium-update.apk');
      if (await file.exists()) await file.delete();

      final id = release['id']?.toString() ?? '';
      await _dio.download(
        '/api/apk/download',
        file.path,
        queryParameters: id.isNotEmpty ? {'id': id} : null,
        onReceiveProgress: (received, total) {
          if (total > 0) progress.value = received / total;
        },
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      if (!await file.exists() || await file.length() < 1024 * 1024) {
        throw StateError('İndirilen dosya geçerli bir APK değil.');
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await dialogFuture;
      if (!context.mounted) return;

      try {
        await Permission.requestInstallPackages.request();
      } catch (_) {}

      try {
        final result = await OpenFilex.open(
          file.path,
          type: 'application/vnd.android.package-archive',
        );
        if (result.type != ResultType.done && context.mounted) {
          _showError(
            context,
            'APK yükleyici açılamadı. ${result.message}'.trim(),
          );
        }
      } catch (e) {
        debugPrint('⚠️ APK installer failed: $e');
        if (context.mounted) {
          _showError(context, 'APK yükleyici açılamadı.');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Update download failed: $e');
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await dialogFuture;
        if (context.mounted) {
          _showError(
            context,
            'Güncelleme indirilemedi. Bağlantınızı kontrol edip tekrar deneyin.',
          );
        }
      }
    } finally {
      progress.dispose();
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Güncelleme Hatası',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes > 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (bytes > 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    if (bytes > 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }
}
