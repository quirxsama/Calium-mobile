import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';
import 'package:calium_stream/features/player/presentation/cubit/player_cubit.dart';
import 'package:calium_stream/features/player/presentation/widgets/in_player_episodes_sheet.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_controls_hud.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_gesture_detector.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_settings_sheet.dart';
import 'package:calium_stream/features/player/presentation/widgets/skip_intro_button.dart';

class AnimePlayerView extends StatelessWidget {
  const AnimePlayerView({
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.seasonNumber = 1,
    this.episodeNumber = 1,
    this.streamUrl = '',
    this.posterUrl = '',
    super.key,
  });

  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String streamUrl;
  final String posterUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerCubit(
        getVideoSourcesUseCase: GetIt.I<GetVideoSourcesUseCase>(),
      )..loadVideoSources(
          animeId: animeId,
          season: seasonNumber,
          episode: episodeNumber,
        ),
      child: _AnimePlayerContent(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeTitle: episodeTitle,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        posterUrl: posterUrl,
      ),
    );
  }
}

class _AnimePlayerContent extends StatefulWidget {
  const _AnimePlayerContent({
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.posterUrl,
  });

  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final int seasonNumber;
  final int episodeNumber;
  final String posterUrl;

  @override
  State<_AnimePlayerContent> createState() => _AnimePlayerContentState();
}

class _AnimePlayerContentState extends State<_AnimePlayerContent> {
  late final Player _player;
  late final VideoController _videoController;

  late int _currentSeasonNumber;
  late int _currentEpisodeNumber;
  late String _currentEpisodeTitle;

  bool _showControls = true;
  bool _isLocked = false;
  double _brightness = 1.0;
  double _volume = 100.0;
  double _currentPlaybackSpeed = 1.0;
  int _subtitleSize = 40;
  bool _autoSkipIntro = true;
  bool _autoNextEpisode = true;
  int _autoNextCountdown = 5;
  Timer? _autoNextTimer;

  Timer? _controlsTimer;
  Duration _position = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  String _currentStreamUrl = '';
  List<EpisodeEntity> _seasonEpisodes = [];
  bool _isDismissedNextEpPrompt = false;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _currentSeasonNumber = widget.seasonNumber;
    _currentEpisodeNumber = widget.episodeNumber;
    _currentEpisodeTitle = widget.episodeTitle;

    // Strict landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _player = Player();
    _videoController = VideoController(_player);

    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        _position = pos;
        _positionNotifier.value = pos;
        // Save progress every 10s
        if (pos.inSeconds > 0 && pos.inSeconds % 10 == 0) {
          _saveCurrentProgress(pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
      }),
      _player.stream.buffer.listen((buf) {
        if (mounted) setState(() => _buffer = buf);
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) setState(() => _isPlaying = playing);
      }),
      _player.stream.buffering.listen((buffering) {
        if (mounted) setState(() => _isBuffering = buffering);
      }),
      _player.stream.volume.listen((vol) {
        if (mounted) setState(() => _volume = vol);
      }),
      _player.stream.completed.listen((completed) {
        if (completed && mounted && _autoNextEpisode && !_isDismissedNextEpPrompt) {
          final cubitState = context.read<PlayerCubit>().state;
          if (cubitState is PlayerReady) {
            final nextEp = cubitState.sourceData.nextEpisode;
            final nextSeason = cubitState.sourceData.nextSeason ?? _currentSeasonNumber;
            if (nextEp != null) {
              _switchEpisode(nextSeason, nextEp, 'Bölüm $nextEp');
            }
          }
        }
      }),
    ]);

    _loadSeasonEpisodes();
    _resetControlsTimer();
  }

  void _saveCurrentProgress(Duration pos) {
    if (pos.inSeconds == 0) return;
    GetIt.I<PlayerRepository>().saveWatchProgress(
      animeId: widget.animeId,
      animeTitle: widget.animeTitle,
      posterUrl: widget.posterUrl,
      episodeId: '${_currentSeasonNumber}_$_currentEpisodeNumber',
      episodeTitle: _currentEpisodeTitle,
      seasonNumber: _currentSeasonNumber,
      episodeNumber: _currentEpisodeNumber,
      position: pos,
      duration: _duration,
    );
  }

  Future<void> _loadSeasonEpisodes() async {
    try {
      final res = await GetIt.I<AnimeDetailRepository>().getEpisodes(
        animeId: widget.animeId,
        season: _currentSeasonNumber,
      );
      res.fold(
        (_) => null,
        (eps) {
          if (mounted) setState(() => _seasonEpisodes = eps);
        },
      );
    } catch (_) {}
  }

  Future<void> _playStream(String url, SubtitleTrackEntity? subtitle) async {
    if (url.isEmpty || url == _currentStreamUrl) return;
    final lastPos = _position;
    _currentStreamUrl = url;

    final isLocal = url.startsWith('/') || url.startsWith('file://');
    final media = isLocal
        ? Media(url)
        : Media(
            url,
            httpHeaders: {
              'Referer': ApiConstants.referer,
              'Origin': ApiConstants.origin,
              'User-Agent': ApiConstants.userAgent,
            },
          );

    await _player.open(media);
    if (lastPos.inSeconds > 5) {
      await _player.seek(lastPos);
    }

    if (subtitle != null && subtitle.url.isNotEmpty) {
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(
          subtitle.url,
          title: subtitle.name,
          language: subtitle.group,
        ),
      );
    }
  }

  void _startAutoNextCountdown(int nextSeason, int nextEp) {
    if (_autoNextTimer != null) return;
    setState(() => _autoNextCountdown = 5);
    _autoNextTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_autoNextCountdown <= 1) {
        timer.cancel();
        _autoNextTimer = null;
        _switchEpisode(nextSeason, nextEp, 'Bölüm $nextEp');
      } else {
        setState(() => _autoNextCountdown--);
      }
    });
  }

  void _cancelAutoNextCountdown() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    setState(() => _isDismissedNextEpPrompt = true);
  }

  void _switchEpisode(int season, int episode, String? title) {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;

    setState(() {
      _currentSeasonNumber = season;
      _currentEpisodeNumber = episode;
      _currentEpisodeTitle = title ?? 'Bölüm $episode';
      _position = Duration.zero;
      _positionNotifier.value = Duration.zero;
      _duration = Duration.zero;
      _currentStreamUrl = '';
      _isDismissedNextEpPrompt = false;
      _showControls = true;
    });

    _player.stop();
    _loadSeasonEpisodes();
    _resetControlsTimer();

    context.read<PlayerCubit>().loadVideoSources(
          animeId: widget.animeId,
          season: season,
          episode: episode,
        );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetControlsTimer();
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _showControls = true;
    });
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(milliseconds: 4000), () {
      if (mounted && _isPlaying && !_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _openSettingsSheet(PlayerReady state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return PlayerSettingsSheet(
          audioGroups: state.sourceData.audioGroups,
          selectedAudioGroup: state.selectedAudioGroup,
          selectedStream: state.selectedStream,
          subtitles: state.sourceData.subtitles,
          selectedSubtitle: state.selectedSubtitle,
          playbackSpeed: state.playbackSpeed,
          subtitleSize: _subtitleSize,
          isFitCover: state.isFitCover,
          autoSkipIntro: _autoSkipIntro,
          autoNextEpisode: _autoNextEpisode,
          onAudioGroupSelected: (group) {
            context.read<PlayerCubit>().selectAudioGroup(group);
          },
          onQualitySelected: (stream) {
            context.read<PlayerCubit>().selectQuality(stream);
          },
          onSubtitleSelected: (sub) async {
            context.read<PlayerCubit>().selectSubtitle(sub);
            if (sub == null) {
              await _player.setSubtitleTrack(SubtitleTrack.no());
            } else {
              await _player.setSubtitleTrack(
                SubtitleTrack.uri(sub.url, title: sub.name, language: sub.group),
              );
            }
          },
          onSpeedSelected: (speed) {
            _currentPlaybackSpeed = speed;
            context.read<PlayerCubit>().setPlaybackSpeed(speed);
            _player.setRate(speed);
          },
          onSubtitleSizeChanged: (size) {
            setState(() => _subtitleSize = size);
          },
          onFitCoverToggled: () {
            context.read<PlayerCubit>().toggleFitCover();
          },
          onAutoSkipIntroToggled: () {
            setState(() => _autoSkipIntro = !_autoSkipIntro);
          },
          onAutoNextEpisodeToggled: () {
            setState(() => _autoNextEpisode = !_autoNextEpisode);
          },
        );
      },
    );
  }

  void _openEpisodesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return InPlayerEpisodesSheet(
          episodes: _seasonEpisodes,
          currentEpisodeNumber: _currentEpisodeNumber,
          currentSeasonNumber: _currentSeasonNumber,
          onEpisodeSelected: (ep) {
            _switchEpisode(ep.seasonNumber, ep.episodeNumber, ep.title);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _saveCurrentProgress(_position);
    _controlsTimer?.cancel();
    _autoNextTimer?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    _positionNotifier.dispose();
    _player.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          await _player.stop();
          _saveCurrentProgress(_position);
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        },
        child: BlocConsumer<PlayerCubit, PlayerState>(
          listener: (context, state) {
          if (state is PlayerReady) {
            _playStream(state.selectedStream.url, state.selectedSubtitle);
          }
        },
        builder: (context, state) {
          if (state is PlayerLoading || state is PlayerInitial) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Bölüm kaynakları çözümleniyor...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (state is PlayerError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.accentCrimson, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, style: AppTypography.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            );
          }

          if (state is PlayerReady) {
            final isCover = state.isFitCover;
            final introStart = state.sourceData.introStart;
            final introEnd = state.sourceData.introEnd;
            final nextEp = state.sourceData.nextEpisode;
            final nextSeason = state.sourceData.nextSeason ?? _currentSeasonNumber;

            return Stack(
              children: [
                // 1. Video Surface with Gesture Detection & RepaintBoundary
                Positioned.fill(
                  child: PlayerGestureDetector(
                    currentPosition: _position,
                    totalDuration: _duration,
                    isLocked: _isLocked,
                    initialBrightness: _brightness,
                    initialVolume: _volume,
                    onTap: _toggleControls,
                    onDoubleTapLeft: (seconds) {
                      _player.seek(_position - Duration(seconds: seconds));
                      _resetControlsTimer();
                    },
                    onDoubleTapRight: (seconds) {
                      _player.seek(_position + Duration(seconds: seconds));
                      _resetControlsTimer();
                    },
                    onDoubleTapCenter: () {
                      _player.playOrPause();
                      _resetControlsTimer();
                    },
                    onLongPressStart: () {
                      _player.setRate(2.0);
                    },
                    onLongPressEnd: () {
                      _player.setRate(_currentPlaybackSpeed);
                    },
                    onBrightnessChanged: (val) {
                      setState(() => _brightness = val);
                    },
                    onVolumeChanged: (val) {
                      _player.setVolume(val);
                      setState(() => _volume = val);
                    },
                    onSeek: (targetPos) {
                      _player.seek(targetPos);
                      _resetControlsTimer();
                    },
                    child: Center(
                      child: RepaintBoundary(
                        child: Video(
                          controller: _videoController,
                          controls: NoVideoControls,
                          fit: isCover ? BoxFit.cover : BoxFit.contain,
                          subtitleViewConfiguration: SubtitleViewConfiguration(
                            style: TextStyle(
                              height: 1.35,
                              fontSize: _subtitleSize.toDouble(),
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              backgroundColor: const Color(0xbb000000),
                            ),
                            textAlign: TextAlign.center,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Hardware/Custom Brightness Dimmer Overlay
                if (_brightness < 1.0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withOpacity((1.0 - _brightness) * 0.85),
                      ),
                    ),
                  ),

                // 3. Buffering Spinner
                if (_isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),

                // 4. Skip Intro Button / Auto Skip Handler
                if (introStart != null && introEnd != null)
                  ValueListenableBuilder<Duration>(
                    valueListenable: _positionNotifier,
                    builder: (context, pos, _) {
                      final currentSec = pos.inSeconds;

                      // Auto Skip Intro trigger
                      if (_autoSkipIntro && currentSec >= introStart && currentSec <= introStart + 2) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _player.seek(Duration(seconds: introEnd));
                        });
                      }

                      final isInsideIntro = currentSec >= introStart && currentSec < introEnd;
                      if (!isInsideIntro || _autoSkipIntro) return const SizedBox.shrink();

                      return Positioned(
                        bottom: _showControls ? 85 : 28,
                        right: 32,
                        child: SkipIntroButton(
                          isVisible: true,
                          onPressed: () {
                            _player.seek(Duration(seconds: introEnd));
                          },
                        ),
                      );
                    },
                  ),

                // 5. Next Episode Floating Countdown Card
                if (nextEp != null && !_isDismissedNextEpPrompt)
                  ValueListenableBuilder<Duration>(
                    valueListenable: _positionNotifier,
                    builder: (context, pos, _) {
                      final totalSec = _duration.inSeconds;
                      final currentSec = pos.inSeconds;
                      final isNearEnd = totalSec > 45 && currentSec >= (totalSec - 45);

                      if (!isNearEnd) return const SizedBox.shrink();

                      // Trigger Auto Next Countdown if enabled
                      if (_autoNextEpisode && _autoNextTimer == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _startAutoNextCountdown(nextSeason, nextEp);
                        });
                      }

                      return Positioned(
                        bottom: _showControls ? 90 : 32,
                        right: 32,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(220),
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                            border: Border.all(color: AppColors.primary, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(100),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Sonraki Bölüm',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                      if (_autoNextEpisode && _autoNextCountdown > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withAlpha(40),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${_autoNextCountdown}s',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    'Bölüm $nextEp',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () {
                                  _switchEpisode(nextSeason, nextEp, 'Bölüm $nextEp');
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_arrow_rounded, size: 16),
                                    SizedBox(width: 2),
                                    Text('Oynat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                                onPressed: _cancelAutoNextCountdown,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // 6. HUD Overlay with Soft Fade Animation
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: PlayerControlsHUD(
                      isPlaying: _isPlaying,
                      position: _position,
                      positionListenable: _positionNotifier,
                      duration: _duration,
                      buffered: _buffer,
                      animeTitle: widget.animeTitle,
                      episodeTitle: _currentEpisodeTitle,
                      selectedQuality: state.selectedStream.quality,
                      selectedAudioName: state.selectedAudioGroup.name,
                      selectedSubtitleName: state.selectedSubtitle?.name,
                      playbackSpeed: state.playbackSpeed,
                      isFitCover: state.isFitCover,
                      isLocked: _isLocked,
                      onBackgroundTap: _toggleControls,
                      onToggleLock: _toggleLock,
                      onPlayPause: () {
                        _player.playOrPause();
                        _resetControlsTimer();
                      },
                      onSeekForward: () {
                        _player.seek(_position + const Duration(seconds: 10));
                        _resetControlsTimer();
                      },
                      onSeekBackward: () {
                        _player.seek(_position - const Duration(seconds: 10));
                        _resetControlsTimer();
                      },
                      onSeek: (val) {
                        _player.seek(val);
                        _resetControlsTimer();
                      },
                      onSeekStart: () {
                        _controlsTimer?.cancel();
                      },
                      onSeekEnd: () {
                        _resetControlsTimer();
                      },
                      onBack: () => Navigator.of(context).pop(),
                      onOpenAudioModal: () => _openSettingsSheet(state),
                      onOpenQualityModal: () => _openSettingsSheet(state),
                      onOpenSubtitleModal: () => _openSettingsSheet(state),
                      onOpenSpeedModal: () => _openSettingsSheet(state),
                      onOpenEpisodesModal: _openEpisodesSheet,
                      onToggleAspectRatio: () {
                        context.read<PlayerCubit>().toggleFitCover();
                      },
                      onPreviousEpisode: _currentEpisodeNumber > 1
                          ? () => _switchEpisode(
                                _currentSeasonNumber,
                                _currentEpisodeNumber - 1,
                                'Bölüm ${_currentEpisodeNumber - 1}',
                              )
                          : null,
                      onNextEpisode: nextEp != null
                          ? () => _switchEpisode(
                                nextSeason,
                                nextEp,
                                'Bölüm $nextEp',
                              )
                          : null,
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      ),
    );
  }
}
