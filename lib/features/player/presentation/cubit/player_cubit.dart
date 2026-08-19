import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:calium_stream/features/downloads/data/datasources/download_service.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
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
    this.playbackSpeed = 1.0,
    this.isFitCover = false,
  });

  final EpisodeSourceEntity sourceData;
  final AudioGroupEntity selectedAudioGroup;
  final VideoStreamItemEntity selectedStream;
  final SubtitleTrackEntity? selectedSubtitle;
  final double playbackSpeed;
  final bool isFitCover;

  PlayerReady copyWith({
    EpisodeSourceEntity? sourceData,
    AudioGroupEntity? selectedAudioGroup,
    VideoStreamItemEntity? selectedStream,
    SubtitleTrackEntity? selectedSubtitle,
    bool clearSubtitle = false,
    double? playbackSpeed,
    bool? isFitCover,
  }) {
    return PlayerReady(
      sourceData: sourceData ?? this.sourceData,
      selectedAudioGroup: selectedAudioGroup ?? this.selectedAudioGroup,
      selectedStream: selectedStream ?? this.selectedStream,
      selectedSubtitle: clearSubtitle ? null : (selectedSubtitle ?? this.selectedSubtitle),
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
        playbackSpeed,
        isFitCover,
      ];
}

final class PlayerError extends PlayerState {
  const PlayerError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

class PlayerCubit extends Cubit<PlayerState> {
  PlayerCubit({required GetVideoSourcesUseCase getVideoSourcesUseCase})
      : _getVideoSourcesUseCase = getVideoSourcesUseCase,
        super(PlayerInitial());

  final GetVideoSourcesUseCase _getVideoSourcesUseCase;

  Future<void> loadVideoSources({
    required String animeId,
    required int season,
    required int episode,
    String? localFilePath,
  }) async {
    emit(PlayerLoading());

    // 1. Check if localFilePath passed or completed task exists in DownloadService
    String? targetPath = localFilePath;
    if (targetPath == null || targetPath.isEmpty) {
      final taskId = '${animeId}_s${season}_ep$episode';
      final tasks = DownloadService.instance.currentTasks;
      for (final t in tasks) {
        final matches = (t.id == taskId || (t.animeId == animeId && t.seasonNumber == season && t.episodeNumber == episode));
        if (matches && t.status == DownloadStatus.completed && t.savePath.isNotEmpty && File(t.savePath).existsSync()) {
          targetPath = t.savePath;
          break;
        }
      }
    }

    if (targetPath != null && targetPath.isNotEmpty && File(targetPath).existsSync()) {
      final localStream = VideoStreamItemEntity(
        quality: 'Çevrimdışı (Yerel İndirme)',
        url: targetPath,
        type: 'file',
      );
      final localAudio = AudioGroupEntity(
        name: 'Yerel İndirme',
        group: 'local',
        streams: [localStream],
      );
      final syntheticSource = EpisodeSourceEntity(
        audioGroups: [localAudio],
        subtitles: const [],
      );

      emit(
        PlayerReady(
          sourceData: syntheticSource,
          selectedAudioGroup: localAudio,
          selectedStream: localStream,
        ),
      );
      return;
    }

    final result = await _getVideoSourcesUseCase(
      GetVideoSourcesParams(
        animeId: animeId,
        season: season,
        episode: episode,
      ),
    );

    result.fold(
      (failure) {
        final msg = failure.message;
        final isOffline = msg.contains('SocketException') ||
            msg.contains('Failed host lookup') ||
            msg.contains('anizium') ||
            msg.contains('HandshakeException');
        if (isOffline) {
          emit(const PlayerError(
            message: 'İnternet bağlantısı kurulamadı. Bu bölümü çevrimdışı izlemek için önceden indirmiş olmanız gerekir.',
          ));
        } else {
          emit(PlayerError(message: failure.message));
        }
      },
      (data) {
        if (data.audioGroups.isEmpty) {
          emit(const PlayerError(message: 'Bu bölüm için video kaynağı bulunamadı.'));
          return;
        }

        // Prefer original (Japanese) or first available
        final initialAudio = data.audioGroups.firstWhere(
          (g) => g.group == 'original' || g.name.contains('Japonca'),
          orElse: () => data.audioGroups.first,
        );

        if (initialAudio.streams.isEmpty) {
          emit(const PlayerError(message: 'Bu ses grubunda video akışı bulunamadı.'));
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

    emit(curr.copyWith(
      selectedAudioGroup: audioGroup,
      selectedStream: matchedStream,
    ));
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
