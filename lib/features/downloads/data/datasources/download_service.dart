import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';

enum DownloadStatus { pending, resolving, downloading, completed, failed, paused }

class DownloadTaskEntity extends Equatable {
  const DownloadTaskEntity({
    required this.id,
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.posterUrl,
    required this.downloadUrl,
    this.localPosterPath = '',
    this.quality,
    this.audioName,
    this.savePath = '',
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.pending,
    this.speedBytesPerSec = 0,
  });

  final String id;
  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final int episodeNumber;
  final int seasonNumber;
  final String posterUrl;
  final String localPosterPath;
  final String downloadUrl;
  final String? quality;
  final String? audioName;
  final String savePath;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final int speedBytesPerSec;

  DownloadTaskEntity copyWith({
    String? downloadUrl,
    String? localPosterPath,
    String? quality,
    String? audioName,
    String? savePath,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    DownloadStatus? status,
    int? speedBytesPerSec,
  }) {
    return DownloadTaskEntity(
      id: id,
      animeId: animeId,
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      episodeNumber: episodeNumber,
      seasonNumber: seasonNumber,
      posterUrl: posterUrl,
      localPosterPath: localPosterPath ?? this.localPosterPath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      quality: quality ?? this.quality,
      audioName: audioName ?? this.audioName,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'animeId': animeId,
    'animeTitle': animeTitle,
    'episodeTitle': episodeTitle,
    'episodeNumber': episodeNumber,
    'seasonNumber': seasonNumber,
    'posterUrl': posterUrl,
    'localPosterPath': localPosterPath,
    'downloadUrl': downloadUrl,
    'quality': quality,
    'audioName': audioName,
    'savePath': savePath,
    'progress': progress,
    'receivedBytes': receivedBytes,
    'totalBytes': totalBytes,
    'status': status.index,
  };

  factory DownloadTaskEntity.fromMap(Map<String, dynamic> map) {
    return DownloadTaskEntity(
      id: map['id'] as String,
      animeId: map['animeId'] as String,
      animeTitle: map['animeTitle'] as String,
      episodeTitle: map['episodeTitle'] as String,
      episodeNumber: map['episodeNumber'] as int,
      seasonNumber: map['seasonNumber'] as int,
      posterUrl: map['posterUrl'] as String? ?? '',
      localPosterPath: map['localPosterPath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
      quality: map['quality'] as String?,
      audioName: map['audioName'] as String?,
      savePath: map['savePath'] as String? ?? '',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      receivedBytes: map['receivedBytes'] as int? ?? 0,
      totalBytes: map['totalBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
    );
  }

  @override
  List<Object?> get props => [
        id, animeId, animeTitle, episodeTitle, episodeNumber,
        seasonNumber, posterUrl, localPosterPath, downloadUrl, quality, audioName, savePath,
        progress, receivedBytes, totalBytes, status, speedBytesPerSec,
      ];
}

class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  static const int _maxConcurrent = 2;
  static const String _boxName = 'download_tasks';

  final List<DownloadTaskEntity> _tasks = [];
  final StreamController<List<DownloadTaskEntity>> _tasksController =
      StreamController<List<DownloadTaskEntity>>.broadcast();
  final Map<String, CancelToken> _cancelTokens = {};
  final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': ApiConstants.userAgent,
      'Referer': ApiConstants.referer,
      'Origin': ApiConstants.origin,
      'cf-control': ApiConstants.cfControl,
      'user-session': ApiConstants.userSession,
      'accept': '*/*',
    },
    followRedirects: true,
    maxRedirects: 5,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
  ));

  int get _activeDownloads =>
      _tasks.where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.resolving).length;

  Stream<List<DownloadTaskEntity>> get tasksStream => _tasksController.stream;
  List<DownloadTaskEntity> get currentTasks => List.unmodifiable(_tasks);

  /// Initialize: load persisted tasks from Hive and validate file integrity
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    for (final key in box.keys) {
      try {
        final map = Map<String, dynamic>.from(box.get(key) as Map);
        final task = DownloadTaskEntity.fromMap(map);
        
        // Validate completed tasks have non-empty, existing video files (> 100KB)
        if (task.status == DownloadStatus.completed) {
          final file = File(task.savePath);
          if (!file.existsSync() || file.lengthSync() < 100 * 1024) {
            final failedTask = task.copyWith(status: DownloadStatus.failed);
            _tasks.add(failedTask);
            await box.put(key, failedTask.toMap());
            continue;
          }
        }

        // Reset downloading/resolving tasks to paused on restart
        if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.resolving) {
          final pausedTask = task.copyWith(status: DownloadStatus.paused);
          _tasks.add(pausedTask);
          await box.put(key, pausedTask.toMap());
        } else {
          _tasks.add(task);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to restore download task: $e');
      }
    }
    _notify();
  }

  void _notify() {
    _tasksController.add(List.unmodifiable(_tasks));
  }

  Future<void> _persistTask(DownloadTaskEntity task) async {
    final box = await Hive.openBox(_boxName);
    await box.put(task.id, task.toMap());
  }

  Future<void> _removePersistedTask(String id) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(id);
  }

  void addTask({
    required String animeId,
    required String animeTitle,
    required String episodeTitle,
    required int episodeNumber,
    required int seasonNumber,
    required String posterUrl,
    required String downloadUrl,
    String? quality,
    String? audioName,
  }) {
    final cleanQuality = (quality ?? 'default').replaceAll(RegExp(r'\s+'), '_');
    final cleanAudio = (audioName ?? 'default').replaceAll(RegExp(r'\s+'), '_');
    final id = '${animeId}_s${seasonNumber}_ep${episodeNumber}_${cleanQuality}_$cleanAudio';
    if (_tasks.any((t) => t.id == id)) return;

    final task = DownloadTaskEntity(
      id: id,
      animeId: animeId,
      animeTitle: animeTitle,
      episodeTitle: episodeTitle,
      episodeNumber: episodeNumber,
      seasonNumber: seasonNumber,
      posterUrl: posterUrl,
      downloadUrl: downloadUrl,
      quality: quality,
      audioName: audioName,
    );

    _tasks.add(task);
    _notify();
    _persistTask(task);
    _processQueue();
  }

  void _processQueue() {
    if (_activeDownloads >= _maxConcurrent) return;
    final pending = _tasks.where((t) => t.status == DownloadStatus.pending).toList();
    for (final task in pending) {
      if (_activeDownloads >= _maxConcurrent) break;
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTaskEntity task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    String resolvedUrl = task.downloadUrl;
    String? resolvedQuality = task.quality;
    String? resolvedAudio = task.audioName;

    // Step 1: Resolve video URL if empty
    if (resolvedUrl.isEmpty) {
      _updateTask(index, status: DownloadStatus.resolving);
      try {
        final useCase = GetIt.I<GetVideoSourcesUseCase>();
        final result = await useCase.call(
          GetVideoSourcesParams(
            animeId: task.animeId,
            season: task.seasonNumber,
            episode: task.episodeNumber,
          ),
        );
        result.fold(
          (failure) {
            _updateTask(index, status: DownloadStatus.failed);
            _processQueue();
            return;
          },
          (sourceData) {
            if (sourceData.audioGroups.isNotEmpty &&
                sourceData.audioGroups.first.streams.isNotEmpty) {
              final group = sourceData.audioGroups.first;
              resolvedAudio ??= group.name;
              final streams = group.streams;
              resolvedUrl = streams.first.url;
              resolvedQuality ??= streams.first.quality;
            }
          },
        );
      } catch (e) {
        debugPrint('⚠️ Failed to resolve video URL: $e');
        _updateTask(index, status: DownloadStatus.failed);
        _processQueue();
        return;
      }
    }

    if (resolvedUrl.isEmpty) {
      _updateTask(index, status: DownloadStatus.failed);
      _processQueue();
      return;
    }

    // Step 2: Determine save path & local poster path
    String savePath = task.savePath;
    String localPosterPath = task.localPosterPath;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      if (savePath.isEmpty) {
        savePath = '${downloadDir.path}/${task.id}.mp4';
      }

      // Pre-cache episode poster thumbnail locally for guaranteed offline viewing
      if (localPosterPath.isEmpty || !File(localPosterPath).existsSync()) {
        final thumbDir = Directory('${downloadDir.path}/thumbnails');
        if (!await thumbDir.exists()) {
          await thumbDir.create(recursive: true);
        }
        final safeAnimeId = task.animeId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final targetThumbPath = '${thumbDir.path}/${safeAnimeId}_poster.jpg';
        if (task.posterUrl.isNotEmpty) {
          try {
            final posterUrl = task.posterUrl.startsWith('http')
                ? task.posterUrl
                : 'https://calium.fun${task.posterUrl}';
            await _dio.download(posterUrl, targetThumbPath);
            localPosterPath = targetThumbPath;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to setup download directory: $e');
    }

    if (savePath.isEmpty) {
      _updateTask(index, status: DownloadStatus.failed);
      _processQueue();
      return;
    }

    // Step 3: Start download
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;
    _updateTask(
      index,
      status: DownloadStatus.downloading,
      downloadUrl: resolvedUrl,
      quality: resolvedQuality,
      audioName: resolvedAudio,
      savePath: savePath,
      localPosterPath: localPosterPath,
    );

    int lastReceivedBytes = 0;
    DateTime lastSpeedCheck = DateTime.now();

    try {
      await _dio.download(
        resolvedUrl,
        savePath,
        options: Options(
          headers: {
            'User-Agent': ApiConstants.userAgent,
            'Referer': ApiConstants.referer,
            'Origin': ApiConstants.origin,
            'cf-control': ApiConstants.cfControl,
            'user-session': ApiConstants.userSession,
            'accept': '*/*',
          },
          followRedirects: true,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final now = DateTime.now();
            final elapsed = now.difference(lastSpeedCheck).inMilliseconds;
            int speed = 0;
            if (elapsed > 500) {
              speed = ((received - lastReceivedBytes) * 1000 ~/ elapsed);
              lastReceivedBytes = received;
              lastSpeedCheck = now;
            }
            final idx = _tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              _tasks[idx] = _tasks[idx].copyWith(
                progress: received / total,
                receivedBytes: received,
                totalBytes: total,
                speedBytesPerSec: speed > 0 ? speed : _tasks[idx].speedBytesPerSec,
              );
              _notify();
            }
          }
        },
      );

      final downloadedFile = File(savePath);
      final validSize = downloadedFile.existsSync() ? downloadedFile.lengthSync() : 0;
      if (validSize < 100 * 1024) {
        // Less than 100KB is invalid / 403 error page
        try {
          if (downloadedFile.existsSync()) downloadedFile.deleteSync();
        } catch (_) {}
        final failIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (failIdx != -1) {
          _updateTask(failIdx, status: DownloadStatus.failed);
        }
      } else {
        final finishIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (finishIdx != -1) {
          _updateTask(
            finishIdx,
            status: DownloadStatus.completed,
            progress: 1.0,
            receivedBytes: validSize,
            totalBytes: validSize,
          );
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Paused by user
        final pauseIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (pauseIdx != -1) {
          _updateTask(pauseIdx, status: DownloadStatus.paused);
        }
      } else {
        final failIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (failIdx != -1) {
          _updateTask(failIdx, status: DownloadStatus.failed);
        }
      }
    } catch (_) {
      final failIdx = _tasks.indexWhere((t) => t.id == task.id);
      if (failIdx != -1) {
        _updateTask(failIdx, status: DownloadStatus.failed);
      }
    } finally {
      _cancelTokens.remove(task.id);
      _processQueue();
    }
  }

  void _updateTask(int index, {
    DownloadStatus? status,
    double? progress,
    String? downloadUrl,
    String? localPosterPath,
    String? quality,
    String? audioName,
    String? savePath,
    int? receivedBytes,
    int? totalBytes,
  }) {
    if (index < 0 || index >= _tasks.length) return;
    _tasks[index] = _tasks[index].copyWith(
      status: status,
      progress: progress,
      downloadUrl: downloadUrl,
      localPosterPath: localPosterPath,
      quality: quality,
      audioName: audioName,
      savePath: savePath,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
    );
    _notify();
    _persistTask(_tasks[index]);
  }

  void pauseTask(String id) {
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('paused');
    }
  }

  void resumeTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1 && _tasks[index].status == DownloadStatus.paused) {
      _tasks[index] = _tasks[index].copyWith(status: DownloadStatus.pending);
      _notify();
      _persistTask(_tasks[index]);
      _processQueue();
    }
  }

  void retryTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1 && _tasks[index].status == DownloadStatus.failed) {
      _tasks[index] = _tasks[index].copyWith(
        status: DownloadStatus.pending,
        progress: 0.0,
        receivedBytes: 0,
      );
      _notify();
      _persistTask(_tasks[index]);
      _processQueue();
    }
  }

  void removeTask(String id) {
    pauseTask(id);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      // Delete file if exists
      final path = _tasks[index].savePath;
      if (path.isNotEmpty) {
        try {
          final file = File(path);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
      }
    }
    _tasks.removeWhere((t) => t.id == id);
    _notify();
    _removePersistedTask(id);
    _processQueue();
  }
}
