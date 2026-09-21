import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/services/notification_service.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';

enum DownloadStatus {
  pending,
  resolving,
  downloading,
  completed,
  failed,
  paused,
}

extension on CancelToken {
  void throwIfCancellationRequested() {
    if (isCancelled) throw cancelError!;
  }
}

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
    this.localSubtitles = const [],
    this.quality,
    this.audioName,
    this.savePath = '',
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.pending,
    this.speedBytesPerSec = 0,
    this.errorMessage = '',
  });

  final String id;
  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final int episodeNumber;
  final int seasonNumber;
  final String posterUrl;
  final String localPosterPath;
  final List<Map<String, String>> localSubtitles;
  final String downloadUrl;
  final String? quality;
  final String? audioName;
  final String savePath;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final int speedBytesPerSec;
  final String errorMessage;

  DownloadTaskEntity copyWith({
    String? downloadUrl,
    String? localPosterPath,
    List<Map<String, String>>? localSubtitles,
    String? quality,
    String? audioName,
    String? savePath,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    DownloadStatus? status,
    int? speedBytesPerSec,
    String? errorMessage,
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
      localSubtitles: localSubtitles ?? this.localSubtitles,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      quality: quality ?? this.quality,
      audioName: audioName ?? this.audioName,
      savePath: savePath ?? this.savePath,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      errorMessage: errorMessage ?? this.errorMessage,
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
    'localSubtitles': localSubtitles,
    'downloadUrl': downloadUrl,
    'quality': quality,
    'audioName': audioName,
    'savePath': savePath,
    'progress': progress,
    'receivedBytes': receivedBytes,
    'totalBytes': totalBytes,
    'status': status.index,
    'errorMessage': errorMessage,
  };

  factory DownloadTaskEntity.fromMap(Map<String, dynamic> map) {
    final rawSubs = map['localSubtitles'];
    List<Map<String, String>> subs = [];
    if (rawSubs is List) {
      subs = rawSubs
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();
    }

    return DownloadTaskEntity(
      id: map['id'] as String,
      animeId: map['animeId'] as String,
      animeTitle: map['animeTitle'] as String,
      episodeTitle: map['episodeTitle'] as String,
      episodeNumber: map['episodeNumber'] as int,
      seasonNumber: map['seasonNumber'] as int,
      posterUrl: map['posterUrl'] as String? ?? '',
      localPosterPath: map['localPosterPath'] as String? ?? '',
      localSubtitles: subs,
      downloadUrl: map['downloadUrl'] as String? ?? '',
      quality: map['quality'] as String?,
      audioName: map['audioName'] as String?,
      savePath: map['savePath'] as String? ?? '',
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      receivedBytes: map['receivedBytes'] as int? ?? 0,
      totalBytes: map['totalBytes'] as int? ?? 0,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      errorMessage: map['errorMessage'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    animeId,
    animeTitle,
    episodeTitle,
    episodeNumber,
    seasonNumber,
    posterUrl,
    localPosterPath,
    localSubtitles,
    downloadUrl,
    quality,
    audioName,
    savePath,
    progress,
    receivedBytes,
    totalBytes,
    status,
    speedBytesPerSec,
    errorMessage,
  ];
}

String _formatSpeed(int bytesPerSec) {
  if (bytesPerSec > 1048576) {
    return '${(bytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
  }
  if (bytesPerSec > 1024) {
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }
  return '$bytesPerSec B/s';
}

class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  static const int _maxConcurrent = 2;
  static const String _boxName = 'download_tasks';
  static const MethodChannel _nativeChannel = MethodChannel(
    'com.calium.app/download_service',
  );

  final List<DownloadTaskEntity> _tasks = [];
  final StreamController<List<DownloadTaskEntity>> _tasksController =
      StreamController<List<DownloadTaskEntity>>.broadcast();
  final Map<String, CancelToken> _cancelTokens = {};
  DateTime? _lastNativeUpdate;
  bool _nativeRunning = false;
  bool _backgroundUnavailable = false;
  final Dio _dio = Dio(
    BaseOptions(
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
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 45),
    ),
  );

  int get _activeDownloads => _cancelTokens.length;

  Stream<List<DownloadTaskEntity>> get tasksStream => _tasksController.stream;
  List<DownloadTaskEntity> get currentTasks => List.unmodifiable(_tasks);

  /// Initialize: load persisted tasks from Hive and validate file integrity
  Future<void> init() async {
    if (Platform.isAndroid) {
      _nativeChannel.setMethodCallHandler((call) async {
        if (call.method == 'foregroundTimeout') {
          _backgroundUnavailable = true;
          _nativeRunning = false;
          for (final task in List<DownloadTaskEntity>.of(_tasks)) {
            if (task.status == DownloadStatus.pending ||
                _cancelTokens.containsKey(task.id)) {
              pauseTask(task.id);
              _updateTask(
                task.id,
                errorMessage: 'Android arka plan süresi doldu. Uygulamayı açıp devam edin.',
              );
            }
          }
        }
      });
    }
    final box = await Hive.openBox(_boxName);
    for (final key in box.keys) {
      try {
        final map = Map<String, dynamic>.from(box.get(key) as Map);
        final task = DownloadTaskEntity.fromMap(map);

        // Validate completed tasks have non-empty, existing video files (> 100KB)
        if (task.status == DownloadStatus.completed) {
          var currentTask = task;

          // Migrate .mp4 files that are actually MPEG-TS (TS sync byte 0x47)
          if (currentTask.savePath.endsWith('.mp4')) {
            final file = File(currentTask.savePath);
            if (file.existsSync() && file.lengthSync() > 100 * 1024) {
              try {
                final header = file.openSync()..setPositionSync(0);
                final firstByte = header.readByteSync();
                header.closeSync();
                if (firstByte == 0x47) {
                  final newPath = currentTask.savePath.replaceAll(
                    '.mp4',
                    '.ts',
                  );
                  file.renameSync(newPath);
                  currentTask = currentTask.copyWith(savePath: newPath);
                  await box.put(key, currentTask.toMap());
                }
              } catch (_) {}
            }
          }

          final file = File(currentTask.savePath);
          if (!file.existsSync() || file.lengthSync() < 100 * 1024) {
            final failedTask = currentTask.copyWith(
              status: DownloadStatus.failed,
            );
            _tasks.add(failedTask);
            await box.put(key, failedTask.toMap());
            continue;
          }
          _tasks.add(currentTask);
          continue;
        }

        // Reset downloading/resolving tasks to paused on restart
        if (task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.resolving ||
            task.status == DownloadStatus.pending) {
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
    _syncNativeForegroundService();
  }

  void _syncNativeForegroundService() {
    if (!Platform.isAndroid || _backgroundUnavailable) return;
    try {
      final active = _tasks
          .where(
            (t) =>
                _cancelTokens.containsKey(t.id) ||
                t.status == DownloadStatus.pending,
          )
          .toList();
      if (active.isEmpty) {
        if (_nativeRunning) {
          _nativeRunning = false;
          _lastNativeUpdate = null;
          _nativeChannel.invokeMethod('stopForeground').catchError((_) {});
        }
        return;
      }
      final now = DateTime.now();
      if (_lastNativeUpdate != null &&
          now.difference(_lastNativeUpdate!).inMilliseconds < 1000) {
        return;
      }
      _lastNativeUpdate = now;
      final method = _nativeRunning ? 'updateProgress' : 'startForeground';
      _nativeRunning = true;

      final primary = active.first;
      final progress = (primary.progress * 100).toInt();
      final speed = _formatSpeed(primary.speedBytesPerSec);
      final countSuffix = active.length > 1
          ? ' (+${active.length - 1} sırada)'
          : '';

      _nativeChannel
          .invokeMethod(method, {
            'title': primary.animeTitle,
            'content':
                '${primary.seasonNumber}. Sezon ${primary.episodeNumber}. Bölüm$countSuffix',
            'progress': progress,
            'speed': speed,
          })
          .catchError((Object error) {
            debugPrint('Download foreground service unavailable: $error');
            _backgroundUnavailable = true;
            _nativeRunning = false;
            for (final task in List<DownloadTaskEntity>.of(_tasks)) {
              if (task.status == DownloadStatus.pending ||
                  _cancelTokens.containsKey(task.id)) {
                pauseTask(task.id);
                _updateTask(
                  task.id,
                  errorMessage: 'Arka plan indirmesi başlatılamadı. Uygulamayı açıp yeniden deneyin.',
                );
              }
            }
          });
    } catch (_) {}
  }

  Future<void> _persistTask(DownloadTaskEntity task) async {
    final box = Hive.box(_boxName);
    await box.put(task.id, task.toMap());
  }

  Future<void> _removePersistedTask(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
  }

  bool addTask({
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
    final id =
        '${animeId}_s${seasonNumber}_ep${episodeNumber}_${cleanQuality}_$cleanAudio';
    if (_tasks.any((t) => t.id == id) || _cancelTokens.containsKey(id)) {
      return false;
    }

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
    _backgroundUnavailable = false;
    _lastNativeUpdate = null;
    _notify();
    _persistTask(task);
    _processQueue();
    return true;
  }

  int addSeasonTasks({
    required String animeId,
    required String animeTitle,
    required int seasonNumber,
    required String posterUrl,
    required List<EpisodeEntity> episodes,
    String? quality,
    String? audioName,
  }) {
    var added = 0;
    for (final ep in episodes) {
      final epTitle = ep.title ?? 'Bölüm ${ep.episodeNumber}';
      if (addTask(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeTitle: epTitle,
        episodeNumber: ep.episodeNumber,
        seasonNumber: seasonNumber,
        posterUrl: posterUrl,
        downloadUrl: '', // Will resolve automatically when processing queue
        quality: quality,
        audioName: audioName,
      )) {
        added++;
      }
    }
    return added;
  }

  void _processQueue() {
    if (_activeDownloads >= _maxConcurrent) return;
    final pending = _tasks
        .where((t) => t.status == DownloadStatus.pending)
        .toList();
    for (final task in pending) {
      if (_activeDownloads >= _maxConcurrent) break;
      _startDownload(task);
    }
  }

  Future<void> _startDownload(DownloadTaskEntity task) async {
    if (_cancelTokens.containsKey(task.id)) return;
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;
    _updateTask(task.id, status: DownloadStatus.resolving, errorMessage: '');
    try {
      await _downloadTask(task, cancelToken);
    } on DioException catch (e) {
      _updateTask(
        task.id,
        status: CancelToken.isCancel(e)
            ? DownloadStatus.paused
            : DownloadStatus.failed,
        errorMessage: CancelToken.isCancel(e) ? '' : _downloadError(e),
      );
    } catch (e) {
      _updateTask(
        task.id,
        status: DownloadStatus.failed,
        errorMessage: _downloadError(e),
      );
    } finally {
      _cancelTokens.remove(task.id);
      _processQueue();
      _notify();
    }
  }

  Future<void> _downloadTask(
    DownloadTaskEntity task,
    CancelToken cancelToken,
  ) async {
    String resolvedUrl = task.downloadUrl;
    String? resolvedQuality = task.quality;
    String? resolvedAudio = task.audioName;
    List<SubtitleTrackEntity> availableSubtitles = [];

    // Step 1: Resolve video URL & subtitle tracks if needed
    if (resolvedUrl.isEmpty || task.localSubtitles.isEmpty) {
      try {
        final useCase = GetIt.I<GetVideoSourcesUseCase>();
        final result = await useCase.call(
          GetVideoSourcesParams(
            animeId: task.animeId,
            season: task.seasonNumber,
            episode: task.episodeNumber,
          ),
        );
        cancelToken.throwIfCancellationRequested();
        result.fold(
          (failure) {
            if (resolvedUrl.isEmpty) {
              throw StateError('Bölüm bağlantısı alınamadı. Yeniden deneyin.');
            }
          },
          (sourceData) {
            availableSubtitles = sourceData.subtitles;
            final availableGroups = sourceData.audioGroups.where(
              (group) => group.streams.isNotEmpty,
            );
            if (resolvedUrl.isEmpty && availableGroups.isNotEmpty) {
              final group = availableGroups.firstWhere(
                (g) => task.audioName != null && g.name == task.audioName,
                orElse: () => availableGroups.first,
              );
              resolvedAudio ??= group.name;
              final streams = group.streams;
              final matchedStream = streams.firstWhere(
                (s) => task.quality != null && s.quality == task.quality,
                orElse: () => streams.first,
              );
              resolvedUrl = matchedStream.url;
              resolvedQuality ??= matchedStream.quality;
            }
          },
        );
      } catch (e) {
        cancelToken.throwIfCancellationRequested();
        debugPrint('⚠️ Failed to resolve video URL / subtitles: $e');
        if (resolvedUrl.isEmpty) {
          rethrow;
        }
      }
    }

    if (resolvedUrl.isEmpty) {
      throw StateError('İndirilebilir video bağlantısı bulunamadı.');
    }

    // Step 2: Determine save path, local poster path, and download subtitles
    String savePath = task.savePath;
    String localPosterPath = task.localPosterPath;
    List<Map<String, String>> localSubs = List.from(task.localSubtitles);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      if (savePath.isEmpty) {
        final ext = resolvedUrl.contains('.m3u8') ? '.ts' : '.mp4';
        savePath = '${downloadDir.path}/${Uri.encodeComponent(task.id)}$ext';
      }

      // Pre-cache episode poster thumbnail locally for guaranteed offline viewing
      if (localPosterPath.isEmpty || !File(localPosterPath).existsSync()) {
        final thumbDir = Directory('${downloadDir.path}/thumbnails');
        if (!await thumbDir.exists()) {
          await thumbDir.create(recursive: true);
        }
        final safeAnimeId = task.animeId.replaceAll(
          RegExp(r'[^a-zA-Z0-9_-]'),
          '_',
        );
        final targetThumbPath = '${thumbDir.path}/${safeAnimeId}_poster.jpg';
        if (task.posterUrl.isNotEmpty) {
          try {
            final posterUrl = task.posterUrl.startsWith('http')
                ? task.posterUrl
                : 'https://calium.fun${task.posterUrl}';
            await _dio.download(
              posterUrl,
              targetThumbPath,
              cancelToken: cancelToken,
            );
            localPosterPath = targetThumbPath;
          } catch (_) {}
        }
      }

      // Pre-download all available subtitle tracks locally
      if (localSubs.isEmpty && availableSubtitles.isNotEmpty) {
        final subDir = Directory('${downloadDir.path}/subtitles');
        if (!await subDir.exists()) {
          await subDir.create(recursive: true);
        }
        for (final sub in availableSubtitles) {
          try {
            final safeLang = sub.group.replaceAll(
              RegExp(r'[^a-zA-Z0-9_-]'),
              '_',
            );
            final targetSubPath =
                '${subDir.path}/${Uri.encodeComponent(task.id)}_$safeLang.vtt';
            cancelToken.throwIfCancellationRequested();
            await _dio.download(
              sub.url,
              targetSubPath,
              cancelToken: cancelToken,
            );
            if (File(targetSubPath).existsSync() &&
                File(targetSubPath).lengthSync() > 10) {
              localSubs.add({
                'name': sub.name,
                'group': sub.group,
                'path': targetSubPath,
              });
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      cancelToken.throwIfCancellationRequested();
      rethrow;
    }
    cancelToken.throwIfCancellationRequested();

    if (savePath.isEmpty) {
      throw StateError('İndirme klasörü hazırlanamadı.');
    }

    // Step 3: Start download
    final notifId = task.id.hashCode.abs();
    final episodeLabel =
        '${task.seasonNumber}. Sezon ${task.episodeNumber}. Bölüm';

    _updateTask(
      task.id,
      status: DownloadStatus.downloading,
      downloadUrl: resolvedUrl,
      quality: resolvedQuality,
      audioName: resolvedAudio,
      savePath: savePath,
      localPosterPath: localPosterPath,
      localSubtitles: localSubs,
    );

    final tempPath = '$savePath.tmp';
    int lastReceivedBytes = 0;
    DateTime lastSpeedCheck = DateTime.now();

    try {
      if (resolvedUrl.contains('.m3u8')) {
        // HLS Downloader: Parse m3u8, handle encryption/fMP4, concatenate segments
        final hlsHeaders = Options(
          headers: {
            'User-Agent': ApiConstants.userAgent,
            'Referer': ApiConstants.referer,
            'Origin': ApiConstants.origin,
            'cf-control': ApiConstants.cfControl,
            'user-session': ApiConstants.userSession,
          },
        );

        var res = await _dio.get<String>(
          resolvedUrl,
          options: hlsHeaders,
          cancelToken: cancelToken,
        );
        String playlist = res.data ?? '';

        // Resolve master playlist → media playlist
        if (playlist.contains('#EXT-X-STREAM-INF')) {
          final lines = playlist.split('\n');
          String? subPlaylistUrl;
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('#EXT-X-STREAM-INF') &&
                i + 1 < lines.length) {
              if (!lines[i + 1].startsWith('#')) {
                subPlaylistUrl = lines[i + 1].trim();
                break;
              }
            }
          }
          if (subPlaylistUrl != null) {
            resolvedUrl = res.realUri.resolve(subPlaylistUrl).toString();
            res = await _dio.get<String>(
              resolvedUrl,
              options: hlsHeaders,
              cancelToken: cancelToken,
            );
            playlist = res.data ?? '';
          }
        }

        // Reject encrypted HLS — we can't decrypt locally
        if (playlist
            .split('\n')
            .any(
              (line) =>
                  line.trim().startsWith('#EXT-X-KEY:') &&
                  !RegExp(r'METHOD=NONE(?:,|\s|$)').hasMatch(line),
            )) {
          throw StateError('Şifreli yayınlar çevrimdışı indirilemiyor.');
        }
        if (!playlist.contains('#EXT-X-ENDLIST') ||
            playlist.contains('#EXT-X-BYTERANGE') ||
            playlist.contains('BYTERANGE=') ||
            playlist.contains('#EXT-X-DISCONTINUITY')) {
          throw StateError(
            'Bu yayın biçimi çevrimdışı indirmeyi desteklemiyor.',
          );
        }

        final playlistBase = res.realUri;
        final lines = playlist.split('\n');

        // Extract fMP4 initialization segment (#EXT-X-MAP)
        String? initSegmentUrl;
        for (final line in lines) {
          final tLine = line.trim();
          if (tLine.startsWith('#EXT-X-MAP:')) {
            final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(tLine);
            if (uriMatch != null) {
              final uri = uriMatch.group(1)!;
              initSegmentUrl = playlistBase.resolve(uri).toString();
            }
            break;
          }
        }

        // Extract media segment URLs
        final segmentUrls = <String>[];
        for (final line in lines) {
          final tLine = line.trim();
          if (tLine.isNotEmpty && !tLine.startsWith('#')) {
            segmentUrls.add(playlistBase.resolve(tLine).toString());
          }
        }

        if (segmentUrls.isEmpty) throw Exception('No segments found in m3u8');

        final tempFile = File(tempPath);
        final checkpoint = File('$tempPath.json');
        final identity = jsonEncode([initSegmentUrl, segmentUrls]);
        int completedSegments = 0;
        int totalBytesWritten = 0;
        if (await tempFile.exists() && await checkpoint.exists()) {
          try {
            final saved = jsonDecode(await checkpoint.readAsString()) as Map;
            final count = saved['segments'] as int;
            final bytes = saved['bytes'] as int;
            if (saved['identity'] == identity &&
                count >= 0 &&
                count <= segmentUrls.length &&
                bytes >= 0 &&
                bytes <= await tempFile.length()) {
              completedSegments = count;
              totalBytesWritten = bytes;
            }
          } catch (_) {
            // An incomplete checkpoint is never trusted.
          }
        }
        final sink = await tempFile.open(mode: FileMode.append);
        try {
          await sink.truncate(totalBytesWritten);
          await sink.setPosition(totalBytesWritten);
          lastReceivedBytes = totalBytesWritten;

          // Write fMP4 init segment first if present
          if (initSegmentUrl != null && totalBytesWritten == 0) {
            final initRes = await _dio.get<List<int>>(
              initSegmentUrl,
              options: hlsHeaders.copyWith(responseType: ResponseType.bytes),
              cancelToken: cancelToken,
            );
            if (initRes.data == null || initRes.data!.isEmpty) {
              throw StateError('Video başlangıç parçası alınamadı.');
            }
            await sink.writeFrom(initRes.data!);
            totalBytesWritten += initRes.data!.length;
          }

          final totalSegments = segmentUrls.length;
          const batchSize = 3;

          for (
            int chunkStart = completedSegments;
            chunkStart < totalSegments;
            chunkStart += batchSize
          ) {
            cancelToken.throwIfCancellationRequested();
            final chunkEnd = (chunkStart + batchSize < totalSegments)
                ? chunkStart + batchSize
                : totalSegments;

            // Download all segments in this batch concurrently
            final batchFutures = <Future<List<int>>>[];
            for (int i = chunkStart; i < chunkEnd; i++) {
              final segUrl = segmentUrls[i];
              batchFutures.add(
                _fetchSegmentWithRetry(segUrl, hlsHeaders, cancelToken),
              );
            }

            final batchResults = await Future.wait(batchFutures);
            cancelToken.throwIfCancellationRequested();

            for (final segBytes in batchResults) {
              await sink.writeFrom(segBytes);
              totalBytesWritten += segBytes.length;
            }
            await sink.flush();
            final nextCheckpoint = File('$tempPath.json.new');
            await nextCheckpoint.writeAsString(
              jsonEncode({
                'identity': identity,
                'segments': chunkEnd,
                'bytes': totalBytesWritten,
              }),
              flush: true,
            );
            await nextCheckpoint.rename(checkpoint.path);
            cancelToken.throwIfCancellationRequested();

            final idx = _tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              final now = DateTime.now();
              final elapsed = now.difference(lastSpeedCheck).inMilliseconds;
              int speed = 0;
              if (elapsed > 250) {
                speed =
                    ((totalBytesWritten - lastReceivedBytes) * 1000 ~/ elapsed);
                lastReceivedBytes = totalBytesWritten;
                lastSpeedCheck = now;
              }
              final currentProgress = chunkEnd / totalSegments;
              _tasks[idx] = _tasks[idx].copyWith(
                progress: currentProgress,
                receivedBytes: totalBytesWritten,
                totalBytes: 0,
                speedBytesPerSec: speed > 0
                    ? speed
                    : _tasks[idx].speedBytesPerSec,
              );
              _notify();
              await _persistTask(_tasks[idx]);
            }
          }
        } finally {
          await sink.close();
        }
      } else {
        int downloadRetries = 0;
        bool downloadSuccess = false;

        while (downloadRetries < 4 && !downloadSuccess) {
          cancelToken.throwIfCancellationRequested();
          try {
            await _downloadFile(resolvedUrl, tempPath, cancelToken, (
              received,
              total,
            ) {
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
                final currentProgress = total > 0 ? received / total : 0.0;
                _tasks[idx] = _tasks[idx].copyWith(
                  progress: currentProgress,
                  receivedBytes: received,
                  totalBytes: total,
                  speedBytesPerSec: speed > 0
                      ? speed
                      : _tasks[idx].speedBytesPerSec,
                  errorMessage: '',
                );
                _notify();
              }
            });
            downloadSuccess = true;
          } on DioException catch (e) {
            if (e.type == DioExceptionType.cancel) rethrow;
            downloadRetries++;
            if (downloadRetries >= 4) rethrow;
            if (e.response?.statusCode == 401 ||
                e.response?.statusCode == 403) {
              rethrow;
            }
            _updateTask(
              task.id,
              errorMessage: 'Bağlantı yeniden deneniyor ($downloadRetries/3)…',
            );
            await Future.any([
              Future<void>.delayed(Duration(seconds: 2 * downloadRetries)),
              cancelToken.whenCancel,
            ]);
          } catch (e) {
            if (e is FileSystemException || e is StateError) rethrow;
            downloadRetries++;
            if (downloadRetries >= 4) rethrow;
            await Future.any([
              Future<void>.delayed(Duration(seconds: 2 * downloadRetries)),
              cancelToken.whenCancel,
            ]);
          }
        }
      }

      cancelToken.throwIfCancellationRequested();
      final downloadedTempFile = File(tempPath);
      final validSize = downloadedTempFile.existsSync()
          ? downloadedTempFile.lengthSync()
          : 0;
      if (validSize < 100 * 1024) {
        // Less than 100KB is invalid / 403 error page
        try {
          if (downloadedTempFile.existsSync()) downloadedTempFile.deleteSync();
        } catch (_) {}
        final failIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (failIdx != -1) {
          _updateTask(
            task.id,
            status: DownloadStatus.failed,
            errorMessage: 'Video dosyası eksik veya geçersiz. Yeniden deneyin.',
          );
        }
        NotificationService.instance.showDownloadFailedNotification(
          id: notifId,
          animeTitle: task.animeTitle,
          episodeLabel: episodeLabel,
        );
      } else {
        // Atomic rename from temp file to final savePath
        final finalFile = File(savePath);
        if (finalFile.existsSync()) finalFile.deleteSync();
        downloadedTempFile.renameSync(savePath);

        final finishIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (finishIdx != -1) {
          _updateTask(
            task.id,
            status: DownloadStatus.completed,
            progress: 1.0,
            receivedBytes: validSize,
            totalBytes: validSize,
          );
        }
        NotificationService.instance.showDownloadCompletedNotification(
          id: notifId,
          animeTitle: task.animeTitle,
          episodeLabel: episodeLabel,
        );
        final checkpoint = File('$tempPath.json');
        try {
          if (await checkpoint.exists()) await checkpoint.delete();
        } on FileSystemException catch (_) {
          // A leftover checkpoint does not invalidate an already committed video.
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Paused by user
        final pauseIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (pauseIdx != -1) {
          _updateTask(task.id, status: DownloadStatus.paused);
        }
        NotificationService.instance.cancelNotification(notifId);
      } else {
        final failIdx = _tasks.indexWhere((t) => t.id == task.id);
        if (failIdx != -1) {
          _updateTask(
            task.id,
            status: DownloadStatus.failed,
            errorMessage: _downloadError(e),
            downloadUrl:
                e.response?.statusCode == 401 || e.response?.statusCode == 403
                ? ''
                : null,
          );
        }
        NotificationService.instance.showDownloadFailedNotification(
          id: notifId,
          animeTitle: task.animeTitle,
          episodeLabel: episodeLabel,
        );
      }
    } catch (e) {
      final failIdx = _tasks.indexWhere((t) => t.id == task.id);
      if (failIdx != -1) {
        _updateTask(
          task.id,
          status: DownloadStatus.failed,
          errorMessage: _downloadError(e),
        );
      }
      NotificationService.instance.showDownloadFailedNotification(
        id: notifId,
        animeTitle: task.animeTitle,
        episodeLabel: episodeLabel,
      );
    } finally {
      if (!_tasks.any((t) => t.id == task.id)) {
        for (final suffix in ['', '.json', '.json.new']) {
          final file = File('$tempPath$suffix');
          if (await file.exists()) await file.delete();
        }
      }
    }
  }

  Future<List<int>> _fetchSegmentWithRetry(
    String url,
    Options options,
    CancelToken cancelToken,
  ) async {
    int retries = 0;
    while (retries < 3) {
      cancelToken.throwIfCancellationRequested();
      try {
        final res = await _dio.get<List<int>>(
          url,
          options: options.copyWith(
            responseType: ResponseType.bytes,
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
          ),
          cancelToken: cancelToken,
        );
        if (res.data == null || res.data!.isEmpty) {
          throw StateError('Video parçası boş. Yeniden deneyin.');
        }
        return res.data!;
      } catch (e) {
        cancelToken.throwIfCancellationRequested();
        retries++;
        if (retries >= 3) rethrow;
        await Future.any([
          Future<void>.delayed(Duration(seconds: retries * 2)),
          cancelToken.whenCancel,
        ]);
      }
    }
    throw StateError('Video parçası indirilemedi.');
  }

  Future<void> _downloadFile(
    String url,
    String path,
    CancelToken token,
    void Function(int, int) onProgress,
  ) async {
    final file = File(path);
    final checkpoint = File('$path.json');
    var offset = 0;
    String? validator;
    if (await file.exists() && await checkpoint.exists()) {
      try {
        final saved = jsonDecode(await checkpoint.readAsString()) as Map;
        if (saved['url'] == url && saved['validator'] is String) {
          validator = saved['validator'] as String;
          offset = await file.length();
        }
      } catch (_) {}
    }
    token.throwIfCancellationRequested();
    final response = await _dio.get<ResponseBody>(
      url,
      cancelToken: token,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept-Encoding': 'identity',
          if (offset > 0) 'Range': 'bytes=$offset-',
          if (offset > 0) 'If-Range': validator,
        },
        validateStatus: (status) =>
            status == 200 || status == 206 || status == 416,
      ),
    );
    final body = response.data!;
    var total =
        int.tryParse(response.headers.value('content-length') ?? '') ?? 0;
    if (response.statusCode == 416) {
      await body.stream.listen(null).cancel();
      if (await checkpoint.exists()) await checkpoint.delete();
      throw const HttpException('Range no longer valid; restart transfer');
    }
    if (response.statusCode == 206) {
      final range = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$')
          .firstMatch(response.headers.value('content-range') ?? '');
      if (range == null ||
          int.parse(range[1]!) != offset ||
          int.parse(range[2]!) + 1 != int.parse(range[3]!)) {
        await body.stream.listen(null).cancel();
        throw StateError('Sunucu geçersiz devam yanıtı gönderdi.');
      }
      total = int.parse(range[3]!);
    } else {
      offset = 0; // Server ignored Range or If-Range detected a changed file.
    }
    final etag = response.headers.value('etag');
    final nextValidator = etag != null && !etag.startsWith('W/')
        ? etag
        : response.headers.value('last-modified');
    final sink = await file.open(mode: FileMode.append);
    var received = offset;
    try {
      await sink.truncate(offset);
      await sink.setPosition(offset);
      await checkpoint.writeAsString(
        jsonEncode({'url': url, 'validator': nextValidator}),
        flush: true,
      );
      onProgress(received, total);
      await for (final bytes in body.stream) {
        token.throwIfCancellationRequested();
        await sink.writeFrom(bytes);
        received += bytes.length;
        onProgress(received, total);
      }
      token.throwIfCancellationRequested();
      if (total > 0 && received != total) {
        throw const HttpException('Incomplete response body');
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  String _downloadError(Object error) {
    if (error is FileSystemException) {
      return 'Dosya yazılamadı. Boş alanı ve depolama erişimini kontrol edin.';
    }
    if (error is DioException) {
      final code = error.response?.statusCode;
      if (code == 401 || code == 403) {
        return 'Video bağlantısının süresi dolmuş olabilir. Yeniden deneyin.';
      }
      if (code != null) return 'Sunucu hatası ($code). Yeniden deneyin.';
      return 'Bağlantı kesildi veya yanıt alınamadı. Bağlantınızı kontrol edip yeniden deneyin.';
    }
    if (error is StateError) return error.message;
    return 'İndirme tamamlanamadı. Yeniden deneyin.';
  }

  void _updateTask(
    String id, {
    DownloadStatus? status,
    double? progress,
    String? downloadUrl,
    String? localPosterPath,
    List<Map<String, String>>? localSubtitles,
    String? quality,
    String? audioName,
    String? savePath,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0 || index >= _tasks.length) return;
    _tasks[index] = _tasks[index].copyWith(
      status: status,
      progress: progress,
      downloadUrl: downloadUrl,
      localPosterPath: localPosterPath,
      localSubtitles: localSubtitles,
      quality: quality,
      audioName: audioName,
      savePath: savePath,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      errorMessage: errorMessage,
      speedBytesPerSec: status != null && status != DownloadStatus.downloading
          ? 0
          : null,
    );
    _notify();
    _persistTask(_tasks[index]);
  }

  void pauseTask(String id) {
    NotificationService.instance.cancelNotification(id.hashCode.abs());
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('paused');
    } else if (_tasks.any(
      (t) => t.id == id && t.status == DownloadStatus.pending,
    )) {
      _updateTask(id, status: DownloadStatus.paused);
    }
  }

  void resumeTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1 && _tasks[index].status == DownloadStatus.paused) {
      _backgroundUnavailable = false;
      _lastNativeUpdate = null;
      _tasks[index] = _tasks[index].copyWith(
        status: DownloadStatus.pending,
        errorMessage: '',
      );
      _notify();
      _persistTask(_tasks[index]);
      _processQueue();
    }
  }

  void retryTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1 && _tasks[index].status == DownloadStatus.failed) {
      _backgroundUnavailable = false;
      _lastNativeUpdate = null;
      _tasks[index] = _tasks[index].copyWith(
        status: DownloadStatus.pending,
        errorMessage: '',
      );
      _notify();
      _persistTask(_tasks[index]);
      _processQueue();
    }
  }

  void removeTask(String id) {
    NotificationService.instance.cancelNotification(id.hashCode.abs());
    pauseTask(id);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      // 1. Delete video file & temp file
      if (task.savePath.isNotEmpty) {
        try {
          final file = File(task.savePath);
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}
        try {
          final tFile = File('${task.savePath}.tmp');
          if (tFile.existsSync()) tFile.deleteSync();
          for (final suffix in ['.json', '.json.new']) {
            final checkpoint = File('${tFile.path}$suffix');
            if (checkpoint.existsSync()) checkpoint.deleteSync();
          }
        } catch (_) {}
      }

      // 2. Delete all local subtitle files for this task
      for (final sub in task.localSubtitles) {
        final path = sub['path'];
        if (path != null && path.isNotEmpty) {
          try {
            final sFile = File(path);
            if (sFile.existsSync()) sFile.deleteSync();
          } catch (_) {}
        }
      }

      // 3. Delete poster if no other task uses it
      if (task.localPosterPath.isNotEmpty) {
        final otherTasksUsingPoster = _tasks.where(
          (t) => t.id != id && t.localPosterPath == task.localPosterPath,
        );
        if (otherTasksUsingPoster.isEmpty) {
          try {
            final pFile = File(task.localPosterPath);
            if (pFile.existsSync()) pFile.deleteSync();
          } catch (_) {}
        }
      }
    }
    _tasks.removeWhere((t) => t.id == id);
    _notify();
    _removePersistedTask(id);
    _processQueue();
  }

  void removeSeasonTasks(String animeId, int seasonNumber) {
    final seasonTasks = _tasks
        .where((t) => t.animeId == animeId && t.seasonNumber == seasonNumber)
        .toList();
    for (final t in seasonTasks) {
      removeTask(t.id);
    }
  }

  void removeAnimeTasks(String animeId) {
    final animeTasks = _tasks.where((t) => t.animeId == animeId).toList();
    for (final t in animeTasks) {
      removeTask(t.id);
    }
  }
}
