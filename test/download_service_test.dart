import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/downloads/presentation/views/downloads_screen.dart';
import 'package:calium_stream/features/downloads/presentation/widgets/download_options_sheet.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';
import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:dartz/dartz.dart' show Either, Right;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';

class _Sources implements GetVideoSourcesUseCase {
  _Sources(this.result);
  final Future<Either<Failure, EpisodeSourceEntity>> result;
  @override
  Future<Either<Failure, EpisodeSourceEntity>> call(
    GetVideoSourcesParams params,
  ) => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  dotenv.testLoad(fileInput: '');

  late Directory directory;
  late HttpServer server;
  final service = DownloadService.instance;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    dotenv.testLoad(fileInput: '');
    directory = await Directory.systemTemp.createTemp('calium-download-');
    Hive.init(directory.path);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
  });

  tearDown(() async {
    for (final task in service.currentTasks) {
      service.removeTask(task.id);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await server.close(force: true);
    await Hive.close();
    await GetIt.I.reset();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<DownloadTaskEntity> restore(String name, {double progress = 0}) async {
    final task = DownloadTaskEntity(
      id: name,
      animeId: 'test',
      animeTitle: 'Test',
      episodeTitle: 'Test',
      episodeNumber: 1,
      seasonNumber: 1,
      posterUrl: '',
      downloadUrl: 'http://127.0.0.1:${server.port}/$name',
      savePath: '${directory.path}/$name.video',
      localSubtitles: const [
        {'path': 'unused', 'name': 'Test'},
      ],
      status: DownloadStatus.paused,
      progress: progress,
    );
    final box = await Hive.openBox('download_tasks');
    await box.put(task.id, task.toMap());
    await service.init();
    return task;
  }

  Future<DownloadTaskEntity> waitFor(String id, Set<DownloadStatus> statuses) =>
      service.tasksStream
          .map((tasks) => tasks.where((t) => t.id == id))
          .where((tasks) => tasks.isNotEmpty)
          .map((tasks) => tasks.single)
          .firstWhere((task) => statuses.contains(task.status))
          .timeout(const Duration(seconds: 20));

  const terminalStates = {DownloadStatus.failed, DownloadStatus.completed};

  test('a missing HLS segment must not produce a completed video', () async {
    server.listen((request) async {
      if (request.uri.path.endsWith('.m3u8')) {
        request.response.write(
          '#EXTM3U\n#EXTINF:1,\nfirst.ts\n'
          '#EXTINF:1,\nmissing.ts\n#EXT-X-ENDLIST\n',
        );
      } else if (request.uri.path.endsWith('first.ts')) {
        request.response.add(List.filled(150 * 1024, 0x47));
      } else {
        request.response.statusCode = 503;
      }
      await request.response.close();
    });
    final task = await restore('missing.m3u8');
    final terminal = waitFor(task.id, terminalStates);
    service.resumeTask(task.id);
    expect((await terminal).status, DownloadStatus.failed);
    expect(File(task.savePath).existsSync(), isFalse);
  });

  test('source resolution skips empty audio groups', () async {
    server.listen((request) async {
      request.response.add(List.filled(150 * 1024, 1));
      await request.response.close();
    });
    GetIt.I.registerSingleton<GetVideoSourcesUseCase>(
      _Sources(
        Future.value(
          Right(
            EpisodeSourceEntity(
              audioGroups: [
                const AudioGroupEntity(
                  name: 'Empty',
                  group: 'empty',
                  streams: [],
                ),
                AudioGroupEntity(
                  name: 'Japanese',
                  group: 'jp',
                  streams: [
                    VideoStreamItemEntity(
                      quality: '720p',
                      url: 'http://127.0.0.1:${server.port}/source.mp4',
                    ),
                  ],
                ),
              ],
              subtitles: const [],
            ),
          ),
        ),
      ),
    );
    await service.init();
    service.addTask(
      animeId: 'source',
      animeTitle: 'Test',
      episodeTitle: 'Test',
      episodeNumber: 1,
      seasonNumber: 1,
      posterUrl: '',
      downloadUrl: '',
    );
    final result = await waitFor(
      service.currentTasks.single.id,
      terminalStates,
    );
    expect(result.status, DownloadStatus.completed);
    expect(result.audioName, 'Japanese');
  });

  test('HLS pause preserves committed segments and resumes in order', () async {
    final requests = <int, int>{};
    final expected = [for (var i = 0; i < 6; i++) ...List.filled(40 * 1024, i)];
    server.listen((request) async {
      if (request.uri.path.endsWith('.m3u8')) {
        request.response.write(
          '#EXTM3U\n${[for (var i = 0; i < 6; i++) '#EXTINF:1,\n/$i.ts'].join('\n')}\n#EXT-X-ENDLIST',
        );
      } else {
        final index = int.parse(request.uri.path.substring(1).split('.').first);
        requests.update(index, (count) => count + 1, ifAbsent: () => 1);
        request.response.add(List.filled(40 * 1024, index));
      }
      await request.response.close();
    });
    final task = await restore('resume.m3u8');
    var requestedPause = false;
    final subscription = service.tasksStream.listen((tasks) {
      final current = tasks.single;
      if (!requestedPause &&
          current.progress >= 0.5 &&
          current.status == DownloadStatus.downloading) {
        requestedPause = true;
        service.pauseTask(task.id);
      }
    });
    final paused = waitFor(task.id, {DownloadStatus.paused});
    service.resumeTask(task.id);
    await paused;
    await subscription.cancel();
    expect(File(task.savePath).existsSync(), isFalse);
    expect(await File('${task.savePath}.tmp').length(), 120 * 1024);
    final completed = waitFor(task.id, terminalStates);
    service.resumeTask(task.id);
    expect((await completed).status, DownloadStatus.completed);
    expect(await File(task.savePath).readAsBytes(), expected);
    for (var i = 0; i < 3; i++) {
      expect(
        requests[i],
        1,
        reason: 'Committed segments must not be downloaded twice',
      );
    }
  });

  test(
    'MP4 pause resumes with Range and preserves exact file contents',
    () async {
      final expected = List.generate(256 * 1024, (i) => i % 251);
      final ranges = <String?>[];
      server.listen((request) async {
        final range = request.headers.value('range');
        ranges.add(range);
        final start = range == null
            ? 0
            : int.parse(range.substring(6).split('-').first);
        request.response.headers.set('etag', '"version-1"');
        request.response.contentLength = expected.length - start;
        if (range != null) {
          expect(request.headers.value('if-range'), '"version-1"');
          request.response.statusCode = 206;
          request.response.headers.set(
            'content-range',
            'bytes $start-${expected.length - 1}/${expected.length}',
          );
        }
        try {
          for (var i = start; i < expected.length; i += 16 * 1024) {
            final end = (i + 16 * 1024).clamp(0, expected.length);
            request.response.add(expected.sublist(i, end));
            await request.response.flush();
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
          await request.response.close();
        } on SocketException catch (_) {
          // The client deliberately cancels the first connection.
        } on HttpException catch (_) {}
      });
      final task = await restore('resume.mp4');
      var requestedPause = false;
      final subscription = service.tasksStream.listen((tasks) {
        final current = tasks.single;
        if (!requestedPause && current.receivedBytes >= 64 * 1024) {
          requestedPause = true;
          service.pauseTask(task.id);
        }
      });
      final paused = waitFor(task.id, {DownloadStatus.paused});
      service.resumeTask(task.id);
      await paused;
      await subscription.cancel();
      expect(File(task.savePath).existsSync(), isFalse);
      final savedBytes = await File('${task.savePath}.tmp').length();
      final completed = waitFor(task.id, terminalStates);
      service.resumeTask(task.id);
      expect((await completed).status, DownloadStatus.completed);
      expect(ranges, [null, 'bytes=$savedBytes-']);
      expect(await File(task.savePath).readAsBytes(), expected);
    },
  );

  for (final malformedRange in [false, true]) {
    test(
      malformedRange
          ? 'invalid Content-Range is rejected'
          : 'ignored Range overwrites instead of appending',
      () async {
        final expected = List.filled(150 * 1024, 7);
        server.listen((request) async {
          expect(request.headers.value('range'), 'bytes=65536-');
          request.response.headers.set('etag', '"version-1"');
          if (malformedRange) {
            request.response.statusCode = 206;
            request.response.headers.set(
              'content-range',
              'bytes 0-${expected.length - 1}/${expected.length}',
            );
          }
          request.response.add(expected);
          await request.response.close();
        });
        final task = await restore('range.mp4');
        await File('${task.savePath}.tmp').writeAsBytes(List.filled(65536, 1));
        await File('${task.savePath}.tmp.json').writeAsString(
          jsonEncode({'url': task.downloadUrl, 'validator': '"version-1"'}),
        );
        final completed = waitFor(task.id, terminalStates);
        service.resumeTask(task.id);
        expect(
          (await completed).status,
          malformedRange ? DownloadStatus.failed : DownloadStatus.completed,
        );
        if (!malformedRange) {
          expect(await File(task.savePath).readAsBytes(), expected);
        } else {
          expect(File(task.savePath).existsSync(), isFalse);
        }
      },
    );
  }

  test('deleting a running task leaves no final file or checkpoint', () async {
    final requested = Completer<void>();
    final release = Completer<void>();
    server.listen((request) async {
      requested.complete();
      await release.future;
      request.response.add(List.filled(150 * 1024, 1));
      await request.response.close();
    });
    final task = await restore('delete.mp4');
    service.resumeTask(task.id);
    await requested.future;
    service.removeTask(task.id);
    release.complete();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(service.currentTasks, isEmpty);
    expect(File(task.savePath).existsSync(), isFalse);
    expect(File('${task.savePath}.tmp').existsSync(), isFalse);
    expect(File('${task.savePath}.tmp.json').existsSync(), isFalse);
  });

  test(
    'resolution updates the correct task after an earlier task is deleted',
    () async {
      final result = Completer<Either<Failure, EpisodeSourceEntity>>();
      GetIt.I.registerSingleton<GetVideoSourcesUseCase>(
        _Sources(result.future),
      );
      await restore('neighbour.mp4');
      service.addTask(
        animeId: 'resolving',
        animeTitle: 'Test',
        episodeTitle: 'Test',
        episodeNumber: 1,
        seasonNumber: 1,
        posterUrl: '',
        downloadUrl: '',
      );
      final resolving = service.currentTasks.last;
      final terminal = waitFor(resolving.id, terminalStates);
      // Remove the earlier list entry while resolution is in flight.
      service.removeTask('neighbour.mp4');
      result.complete(
        const Right(EpisodeSourceEntity(audioGroups: [], subtitles: [])),
      );
      expect((await terminal).status, DownloadStatus.failed);
      expect(service.currentTasks.single.id, resolving.id);
      expect(Hive.box('download_tasks').containsKey('neighbour.mp4'), isFalse);
    },
  );

  testWidgets('download progress is accurate and layout supports large text', (
    tester,
  ) async {
    // Typography itself is not under test; avoid downloading fonts in offline tests.
    AppTypography.headlineMedium = const TextStyle(fontSize: 20);
    await tester.runAsync(() => restore('ui.m3u8', progress: 0.5));
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const DownloadsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(LinearProgressIndicator),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, 0.5);
      expect(find.byTooltip('İndirmeye devam et'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('download options remain scrollable with large text', (
    tester,
  ) async {
    GetIt.I.registerSingleton<GetVideoSourcesUseCase>(
      _Sources(
        Future.value(
          Right(
            EpisodeSourceEntity(
              audioGroups: [
                const AudioGroupEntity(
                  name: 'Boş',
                  group: 'empty',
                  streams: [],
                ),
                AudioGroupEntity(
                  name: 'Türkçe Dublaj',
                  group: 'tr',
                  streams: [
                    for (final quality in ['2160p', '1080p', '720p', '480p'])
                      VideoStreamItemEntity(
                        quality: quality,
                        url: 'https://example.invalid/video.mp4',
                      ),
                  ],
                ),
              ],
              subtitles: const [],
            ),
          ),
        ),
      ),
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: DownloadOptionsSheet(
            animeId: 'test',
            animeTitle: 'Uzun bir anime başlığı',
            episodeTitle: 'Uzun bir bölüm adı',
            episodeNumber: 1,
            seasonNumber: 1,
            posterUrl: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Boş'), findsNothing);
    final button = find.text('Bölümü indir • 2160p');
    await tester.ensureVisible(button);
    expect(button.hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('selected episode sheet offers only the batch download', (
    tester,
  ) async {
    GetIt.I.registerSingleton<GetVideoSourcesUseCase>(
      _Sources(
        Future.value(
          Right(
            EpisodeSourceEntity(
              audioGroups: [
                AudioGroupEntity(
                  name: 'Türkçe Dublaj',
                  group: 'tr',
                  streams: [
                    VideoStreamItemEntity(
                      quality: '1080p',
                      url: 'https://example.invalid/video.mp4',
                    ),
                  ],
                ),
              ],
              subtitles: const [],
            ),
          ),
        ),
      ),
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: DownloadOptionsSheet(
            animeId: 'test',
            animeTitle: 'Uzun bir anime başlığı',
            episodeTitle: '3 bölüm seçildi',
            episodeNumber: 1,
            seasonNumber: 1,
            posterUrl: '',
            selectionMode: true,
            allSeasonEpisodes: [
              for (var i = 1; i <= 3; i++)
                EpisodeEntity(
                  id: '$i',
                  animeId: 'test',
                  episodeNumber: i,
                  seasonNumber: 1,
                  title: 'Bölüm $i',
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Bölümü indir'), findsNothing);
    final batch = find.text('Seçilenleri indir (3 bölüm)');
    await tester.ensureVisible(batch);
    expect(batch.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
