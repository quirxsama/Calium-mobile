import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calium_stream/core/error/failures.dart';

import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/player/domain/entities/intro_song_entity.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/usecases/get_intro_song_usecase.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';

sealed class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

final class PlayerInitial extends PlayerState {}

final class PlayerLoading extends PlayerState {}

final class PlayerReady extends PlayerState {
  const PlayerReady({
    required this.sourceData,
    required this.selectedAudioGroup,
    required this.selectedStream,
    this.selectedSubtitle,
    this.introSong,
    this.playbackSpeed = 1.0,
    this.isFitCover = false,
  });

  final EpisodeSourceEntity sourceData;
  final AudioGroupEntity selectedAudioGroup;
  final VideoStreamItemEntity selectedStream;
  final SubtitleTrackEntity? selectedSubtitle;
  final IntroSongEntity? introSong;
  final double playbackSpeed;
  final bool isFitCover;

  PlayerReady copyWith({
    EpisodeSourceEntity? sourceData,
    AudioGroupEntity? selectedAudioGroup,
    VideoStreamItemEntity? selectedStream,
    SubtitleTrackEntity? selectedSubtitle,
    bool clearSubtitle = false,
    IntroSongEntity? introSong,
    bool clearIntroSong = false,
    double? playbackSpeed,
    bool? isFitCover,
  }) {
    return PlayerReady(
      sourceData: sourceData ?? this.sourceData,
      selectedAudioGroup: selectedAudioGroup ?? this.selectedAudioGroup,
      selectedStream: selectedStream ?? this.selectedStream,
      selectedSubtitle: clearSubtitle
          ? null
          : (selectedSubtitle ?? this.selectedSubtitle),
      introSong: clearIntroSong ? null : (introSong ?? this.introSong),
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isFitCover: isFitCover ?? this.isFitCover,
    );
  }

  @override
  List<Object?> get props => [
    sourceData,
    selectedAudioGroup,
    selectedStream,
    selectedSubtitle,
    introSong,
    playbackSpeed,
    isFitCover,
  ];
}

final class PlayerError extends PlayerState {
  const PlayerError({required this.message, this.isNetwork = false});

  final String message;
  final bool isNetwork;

  @override
  List<Object?> get props => [message, isNetwork];
}

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit({
    required this._getVideoSourcesUseCase,
    required this._getIntroSongUseCase,
  }) : super(PlayerInitial());

  final GetVideoSourcesUseCase _getVideoSourcesUseCase;
  final GetIntroSongUseCase _getIntroSongUseCase;
  int _sourceRequest = 0;

  bool _isPlayableFile(String path) {
    try {
      final file = File(path);
      return file.existsSync() && file.lengthSync() >= 100 * 1024;
    } on FileSystemException {
      return false;
    }
  }

  Future<void> loadVideoSources({
    required String animeId,
    required int season,
    required int episode,
    String? localFilePath,
  }) async {
    if (isClosed) return;
    final request = ++_sourceRequest;
    emit(PlayerLoading());

    // 1. Check if localFilePath passed or completed task exists in DownloadService
    String? targetPath = localFilePath;
    final uri = Uri.tryParse(targetPath ?? '');
    if (uri?.scheme == 'file') {
      try {
        targetPath = uri!.toFilePath();
      } on UnsupportedError {
        emit(
          const PlayerError(
            message: 'Yerel dosya yolu geçersiz. İndirmelerden yeniden açın.',
          ),
        );
        return;
      }
    } else if (uri?.scheme == 'http' || uri?.scheme == 'https') {
      targetPath = null;
    }
    DownloadTaskEntity? matchedTask;
    final tasks = DownloadService.instance.currentTasks;

    if (targetPath == null || targetPath.isEmpty) {
      final taskId = '${animeId}_s${season}_ep$episode';
      for (final t in tasks) {
        final matches =
            (t.id == taskId ||
            (t.animeId == animeId &&
                t.seasonNumber == season &&
                t.episodeNumber == episode));
        if (matches &&
            t.status == DownloadStatus.completed &&
            t.savePath.isNotEmpty) {
          if (_isPlayableFile(t.savePath)) {
            targetPath = t.savePath;
            matchedTask = t;
            break;
          }
        }
      }
    } else {
      for (final t in tasks) {
        if (t.savePath == targetPath && t.status == DownloadStatus.completed) {
          matchedTask = t;
          break;
        }
      }
    }

    if (targetPath != null && targetPath.isNotEmpty) {
      if (_isPlayableFile(targetPath)) {
        final localStream = VideoStreamItemEntity(
          quality: matchedTask?.quality ?? 'Çevrimdışı (Yerel İndirme)',
          url: targetPath,
          type: 'file',
        );
        final localAudio = AudioGroupEntity(
          name: matchedTask?.audioName ?? 'Yerel İndirme',
          group: 'local',
          streams: [localStream],
        );

        // Find offline subtitles from task metadata
        List<SubtitleTrackEntity> localSubtitles = [];
        if (matchedTask != null && matchedTask.localSubtitles.isNotEmpty) {
          for (final sub in matchedTask.localSubtitles) {
            final sPath = sub['path'] ?? '';
            if (sPath.isNotEmpty && File(sPath).existsSync()) {
              localSubtitles.add(
                SubtitleTrackEntity(
                  name: sub['name'] ?? 'Türkçe',
                  group: sub['group'] ?? 'tr',
                  url: sPath,
                ),
              );
            }
          }
        }

        // Determine if next episode is downloaded offline
        int? nextDownloadedEpisode;
        int? nextDownloadedSeason;
        final nextCandidate = tasks
            .where(
              (t) =>
                  t.animeId == animeId &&
                  t.seasonNumber == season &&
                  t.episodeNumber == episode + 1 &&
                  t.status == DownloadStatus.completed &&
                  _isPlayableFile(t.savePath),
            )
            .toList();
        if (nextCandidate.isNotEmpty) {
          nextDownloadedEpisode = episode + 1;
          nextDownloadedSeason = season;
        }

        final syntheticSource = EpisodeSourceEntity(
          audioGroups: [localAudio],
          subtitles: localSubtitles,
          nextEpisode: nextDownloadedEpisode,
          nextSeason: nextDownloadedSeason,
        );

        SubtitleTrackEntity? initialSubtitle;
        if (localSubtitles.isNotEmpty) {
          initialSubtitle = localSubtitles.firstWhere(
            (s) => s.group == 'tr' || s.name.contains('Türkçe'),
            orElse: () => localSubtitles.first,
          );
        }

        emit(
          PlayerReady(
            sourceData: syntheticSource,
            selectedAudioGroup: localAudio,
            selectedStream: localStream,
            selectedSubtitle: initialSubtitle,
          ),
        );
        return;
      } else {
        emit(
          const PlayerError(
            message: 'İndirilen video bulunamadı veya eksik. İndirmeler ekranından yeniden indirin.',
          ),
        );
        return;
      }
    }

    try {
      final result = await _getVideoSourcesUseCase(
        GetVideoSourcesParams(
          animeId: animeId,
          season: season,
          episode: episode,
        ),
      );
      if (isClosed || request != _sourceRequest) return;

      result.fold(
        (failure) {
          if (failure is NetworkFailure) {
            emit(
              const PlayerError(
                isNetwork: true,
                message: 'İnternet bağlantısı kurulamadı. Bu bölümü çevrimdışı izlemek için önceden indirmiş olmanız gerekir.',
              ),
            );
          } else {
            emit(PlayerError(message: failure.message));
          }
        },
        (data) {
          final availableGroups = data.audioGroups
              .where((g) => g.streams.isNotEmpty)
              .toList();
          if (availableGroups.isEmpty) {
            emit(
              const PlayerError(
                message: 'Bu bölüm için video kaynağı bulunamadı.',
              ),
            );
            return;
          }

          // Prefer original (Japanese) or first available
          final initialAudio = availableGroups.firstWhere(
            (g) => g.group == 'original' || g.name.contains('Japonca'),
            orElse: () => availableGroups.first,
          );

          if (initialAudio.streams.isEmpty) {
            emit(
              const PlayerError(
                message: 'Bu ses grubunda video akışı bulunamadı.',
              ),
            );
            return;
          }

          // Prefer 1080p or highest available stream
          final initialStream = initialAudio.streams.firstWhere(
            (s) => s.quality == '1080p',
            orElse: () => initialAudio.streams.first,
          );

          // Default to Turkish subtitle if available
          SubtitleTrackEntity? initialSubtitle;
          if (data.subtitles.isNotEmpty) {
            initialSubtitle = data.subtitles.firstWhere(
              (s) => s.group == 'tr' || s.name.contains('Türkçe'),
              orElse: () => data.subtitles.first,
            );
          }

          emit(
            PlayerReady(
              sourceData: data,
              selectedAudioGroup: initialAudio,
              selectedStream: initialStream,
              selectedSubtitle: initialSubtitle,
            ),
          );
        },
      );
    } catch (_) {
      if (!isClosed && request == _sourceRequest) {
        emit(
          const PlayerError(
            message: 'Video kaynakları alınamadı. Yeniden deneyin.',
          ),
        );
      }
    }
  }

  Future<void> loadIntroSong({
    required String animeId,
    required String episodeId,
    String? animeName,
    int? season,
    int? episode,
    int? introStart,
    String? streamUrl,
  }) async {
    if (isClosed ||
        state is! PlayerReady ||
        (state as PlayerReady).selectedStream.type == 'file') {
      return;
    }
    final sourceRequest = _sourceRequest;
    try {
      final result = await _getIntroSongUseCase(
        GetIntroSongParams(
          animeId: animeId,
          episodeId: episodeId,
          animeName: animeName,
          season: season,
          episode: episode,
          introStart: introStart,
          streamUrl: streamUrl,
        ),
      );
      if (isClosed || sourceRequest != _sourceRequest) return;

      result.fold((_) => null, (song) {
        if (state is PlayerReady && song != null) {
          final curr = state as PlayerReady;
          emit(curr.copyWith(introSong: song));
        }
      });
    } catch (_) {
      // Optional metadata must not interrupt video playback.
    }
  }

  void selectAudioGroup(AudioGroupEntity audioGroup) {
    if (state is! PlayerReady) return;
    final curr = state as PlayerReady;

    if (audioGroup.streams.isEmpty) return;

    // Match the same quality in the new audio group, or fallback to highest
    final matchedStream = audioGroup.streams.firstWhere(
      (s) => s.quality == curr.selectedStream.quality,
      orElse: () => audioGroup.streams.first,
    );

    emit(
      curr.copyWith(
        selectedAudioGroup: audioGroup,
        selectedStream: matchedStream,
      ),
    );
  }

  void selectQuality(VideoStreamItemEntity stream) {
    if (state is! PlayerReady) return;
    final curr = state as PlayerReady;
    emit(curr.copyWith(selectedStream: stream));
  }

  void selectSubtitle(SubtitleTrackEntity? subtitle) {
    if (state is! PlayerReady) return;
    final curr = state as PlayerReady;
    if (subtitle == null) {
      emit(curr.copyWith(clearSubtitle: true));
    } else {
      emit(curr.copyWith(selectedSubtitle: subtitle));
    }
  }

  void setPlaybackSpeed(double speed) {
    if (state is! PlayerReady) return;
    final curr = state as PlayerReady;
    emit(curr.copyWith(playbackSpeed: speed));
  }

  void toggleFitCover() {
    if (state is! PlayerReady) return;
    final curr = state as PlayerReady;
    emit(curr.copyWith(isFitCover: !curr.isFitCover));
  }
}
