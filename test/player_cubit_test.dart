import 'dart:async';
import 'dart:io';

import 'package:calium_stream/core/error/failures.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/usecases/get_intro_song_usecase.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';
import 'package:calium_stream/features/player/presentation/cubit/player_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class Sources implements GetVideoSourcesUseCase {
  final requests = <Completer<Either<Failure, EpisodeSourceEntity>>>[];
  @override
  Future<Either<Failure, EpisodeSourceEntity>> call(
    GetVideoSourcesParams params,
  ) {
    final result = Completer<Either<Failure, EpisodeSourceEntity>>();
    requests.add(result);
    return result.future;
  }
}

class Intro implements GetIntroSongUseCase {
  final result = Completer<Either<Failure, IntroSongEntity?>>();
  @override
  Future<Either<Failure, IntroSongEntity?>> call(GetIntroSongParams params) =>
      result.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

EpisodeSourceEntity source(String url, {bool emptyOriginal = false}) =>
    EpisodeSourceEntity(
      audioGroups: [
        if (emptyOriginal)
          const AudioGroupEntity(
            name: 'Japonca',
            group: 'original',
            streams: [],
          ),
        AudioGroupEntity(
          name: 'Türkçe',
          group: 'tr',
          streams: [VideoStreamItemEntity(quality: '1080p', url: url)],
        ),
      ],
      subtitles: const [],
    );

void main() {
  setUp(() => dotenv.testLoad(fileInput: ''));
  late Sources sources;
  late Intro intro;
  late PlayerCubit cubit;
  setUp(() {
    sources = Sources();
    intro = Intro();
    cubit = PlayerCubit(
      getVideoSourcesUseCase: sources,
      getIntroSongUseCase: intro,
    );
  });
  tearDown(() => cubit.close());

  test(
    'latest episode wins when source requests finish out of order',
    () async {
      final first = cubit.loadVideoSources(animeId: 'a', season: 1, episode: 1);
      final second = cubit.loadVideoSources(
        animeId: 'a',
        season: 1,
        episode: 2,
      );
      sources.requests[1].complete(Right(source('https://test/second')));
      await second;
      sources.requests[0].complete(Right(source('https://test/first')));
      await first;
      expect(
        (cubit.state as PlayerReady).selectedStream.url,
        'https://test/second',
      );
    },
  );

  test('source response after close does not emit or throw', () async {
    final pending = cubit.loadVideoSources(animeId: 'a', season: 1, episode: 1);
    await cubit.close();
    sources.requests.single.complete(Right(source('https://test/video')));
    await expectLater(pending, completes);
  });

  test(
    'empty preferred audio group does not hide playable alternatives',
    () async {
      final pending = cubit.loadVideoSources(
        animeId: 'a',
        season: 1,
        episode: 1,
      );
      sources.requests.single.complete(
        Right(source('https://test/video', emptyOriginal: true)),
      );
      await pending;
      expect(cubit.state, isA<PlayerReady>());
    },
  );

  test('intro from the previous episode is discarded', () async {
    final first = cubit.loadVideoSources(animeId: 'a', season: 1, episode: 1);
    sources.requests.last.complete(Right(source('https://test/first')));
    await first;
    final song = cubit.loadIntroSong(animeId: 'a', episodeId: '1');
    final second = cubit.loadVideoSources(animeId: 'a', season: 1, episode: 2);
    sources.requests.last.complete(Right(source('https://test/second')));
    await second;
    intro.result.complete(
      const Right(
        IntroSongEntity(title: 'Old song', artist: 'Artist', spotifyUrl: ''),
      ),
    );
    await song;
    expect((cubit.state as PlayerReady).introSong, isNull);
  });

  test('file URI with spaces plays locally without a source request', () async {
    final directory = await Directory.systemTemp.createTemp('calium player ');
    try {
      final file = await File('${directory.path}/episode 1.mp4')
          .writeAsBytes(List.filled(110 * 1024, 1));
      final pending = cubit.loadVideoSources(
        animeId: 'a',
        season: 1,
        episode: 1,
        localFilePath: file.uri.toString(),
      );
      if (sources.requests.isNotEmpty) {
        sources.requests.single.complete(
          const Left(NetworkFailure(message: 'offline')),
        );
      }
      await pending;
      expect(cubit.state, isA<PlayerReady>());
      expect(sources.requests, isEmpty);
      expect((cubit.state as PlayerReady).selectedStream.url, file.path);
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
