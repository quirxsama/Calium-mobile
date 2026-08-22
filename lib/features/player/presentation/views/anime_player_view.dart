import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';

import 'package:calium_stream/core/constants/api_constants.dart';
import 'package:calium_stream/core/services/sync_service.dart';
import 'package:calium_stream/core/services/tracking_service.dart';
import 'package:calium_stream/core/theme/app_colors.dart';
import 'package:calium_stream/core/theme/app_spacing.dart';
import 'package:calium_stream/core/theme/app_typography.dart';
import 'package:calium_stream/features/anime_details/domain/entities/episode_entity.dart';
import 'package:calium_stream/features/anime_details/domain/repositories/anime_detail_repository.dart';
import 'package:calium_stream/features/player/domain/entities/video_source_entity.dart';
import 'package:calium_stream/features/player/domain/repositories/player_repository.dart';
import 'package:calium_stream/features/player/domain/usecases/get_intro_song_usecase.dart';
import 'package:calium_stream/features/player/domain/usecases/get_video_sources_usecase.dart';
import 'package:calium_stream/features/player/presentation/cubit/player_cubit.dart';
import 'package:calium_stream/features/player/presentation/widgets/in_player_episodes_sheet.dart';
import 'package:calium_stream/features/player/presentation/widgets/intro_song_badge.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_controls_hud.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_gesture_detector.dart';
import 'package:calium_stream/features/player/presentation/widgets/player_settings_sheet.dart';
import 'package:calium_stream/features/player/presentation/widgets/skip_intro_button.dart';

class AnimePlayerView extends StatelessWidget {
  const AnimePlayerView({
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.episodeId = '',
    this.seasonNumber = 1,
    this.episodeNumber = 1,
    this.streamUrl = '',
    this.posterUrl = '',
    super.key,
  });

  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final String episodeId;
  final int seasonNumber;
  final int episodeNumber;
  final String streamUrl;
  final String posterUrl;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerCubit(
        getVideoSourcesUseCase: GetIt.I<GetVideoSourcesUseCase>(),
        getIntroSongUseCase: GetIt.I<GetIntroSongUseCase>(),
      )..loadVideoSources(
          animeId: animeId,
          season: seasonNumber,
          episode: episodeNumber,
          localFilePath: streamUrl.isNotEmpty ? streamUrl : null,
        ),
      child: _AnimePlayerContent(
        animeId: animeId,
        animeTitle: animeTitle,
        episodeTitle: episodeTitle,
        episodeId: episodeId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        posterUrl: posterUrl,
        initialStreamUrl: streamUrl,
      ),
    );
  }
}

class _AnimePlayerContent extends StatefulWidget {
  const _AnimePlayerContent({
    required this.animeId,
    required this.animeTitle,
    required this.episodeTitle,
    this.episodeId = '',
    required this.seasonNumber,
    required this.episodeNumber,
    required this.posterUrl,
    this.initialStreamUrl = '',
  });

  final String animeId;
  final String animeTitle;
  final String episodeTitle;
  final String episodeId;
  final int seasonNumber;
  final int episodeNumber;
  final String posterUrl;
  final String initialStreamUrl;

  @override
  State<_AnimePlayerContent> createState() => _AnimePlayerContentState();
}

class _AnimePlayerContentState extends State<_AnimePlayerContent> {
  late final Player _player;
  late final VideoController _videoController;

  late int _currentSeasonNumber;
  late int _currentEpisodeNumber;
  late String _currentEpisodeTitle;
  late String _currentEpisodeId;

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
  int _initialSeekMs = 0;
  double _savedProgressRatio = 0.0;
  Duration? _initialResumeTarget;
  Timer? _resumeSafetyTimer;
  bool _introSkipped = false;
  bool _isDismissedIntroSong = false;
  bool _isIntroSongFadingOut = false;
  Timer? _introSongFadeTimer;
  String _lastIntroSongEpisodeKey = '';
  bool _hasScrobbledCurrentEpisode = false;
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  Timer? _bufferingWatchdogTimer;

  final List<StreamSubscription> _subscriptions = [];

  void _cancelInitialResume() {
    _initialResumeTarget = null;
    _resumeSafetyTimer?.cancel();
    _resumeSafetyTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _currentSeasonNumber = widget.seasonNumber;
    _currentEpisodeNumber = widget.episodeNumber;
    _currentEpisodeTitle = widget.episodeTitle;
    _currentEpisodeId = (widget.episodeId.isNotEmpty && !widget.episodeId.contains('_'))
        ? widget.episodeId
        : '';

    // Read saved progress from Hive
    try {
      final box = Hive.box('history');
      final saved = box.get(widget.animeId);
      if (saved is Map) {
        final sNum = int.tryParse(saved['seasonNumber']?.toString() ?? '');
        final epNum = int.tryParse(saved['episodeNumber']?.toString() ?? '');
        if (sNum == _currentSeasonNumber && epNum == _currentEpisodeNumber) {
          final savedEpId = saved['episodeId']?.toString() ?? '';
          if (_currentEpisodeId.isEmpty && savedEpId.isNotEmpty && !savedEpId.contains('_')) {
            _currentEpisodeId = savedEpId;
          }

          var posMs = 0;
          final rawPos = saved['positionMs'] ?? saved['position_ms'];
          if (rawPos is num && rawPos > 0) {
            posMs = rawPos.toInt();
          } else {
            final rawSec = saved['currentTime'] ??
                saved['current_time'] ??
                saved['time'] ??
                saved['position'] ??
                saved['watchedTime'] ??
                saved['watched_time'];
            if (rawSec is num && rawSec > 0) {
              posMs = rawSec > 100000 ? rawSec.toInt() : (rawSec * 1000).round();
            }
          }

          final durationSec = (saved['duration'] as num?)?.toInt() ?? 0;
          final rawProg = (saved['progress'] as num?)?.toDouble() ?? 0.0;
          final progress = rawProg > 1.0 ? rawProg / 100.0 : rawProg;

          if (posMs <= 0 && progress > 0 && durationSec > 0) {
            posMs = (progress * durationSec * 1000).round();
          }

          if (progress > 0) {
            _savedProgressRatio = progress;
          }

          if (posMs > 3000) {
            _initialSeekMs = posMs;
            _initialResumeTarget = Duration(milliseconds: posMs);
            _resumeSafetyTimer = Timer(const Duration(seconds: 10), () {
              _initialResumeTarget = null;
            });
          }
        }
      }
    } catch (_) {}

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

        // If we have an active initial resume target:
        if (_initialResumeTarget != null) {
          final target = _initialResumeTarget!;
          if (_duration > Duration.zero && pos.inSeconds < target.inSeconds - 3) {
            // Codec reset to 0:00 (due to Android surface resize / decoder reload), re-seek!
            _player.seek(target);
          } else if (pos >= target - const Duration(seconds: 2)) {
            // Player stabilized at target position
            _resumeSafetyTimer?.cancel();
            _resumeSafetyTimer = Timer(const Duration(seconds: 2), () {
              _initialResumeTarget = null;
            });
          }
        }

        // Save progress every 5s if user is not in initial resume loading phase
        if (_initialResumeTarget == null && pos.inSeconds >= 4 && pos.inSeconds % 5 == 0) {
          _saveCurrentProgress(pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (mounted) setState(() => _duration = dur);
        if (_initialResumeTarget != null && dur > Duration.zero) {
          final target = _initialResumeTarget!;
          if (_position.inSeconds < target.inSeconds - 3) {
            final clamped = target > dur ? dur - const Duration(seconds: 5) : target;
            if (clamped > Duration.zero) {
              _player.seek(clamped);
            }
          }
        } else if (_initialResumeTarget == null &&
            _position.inSeconds < 4 &&
            _savedProgressRatio > 0 &&
            _savedProgressRatio < 0.95 &&
            dur > Duration.zero) {
          final target = Duration(
            milliseconds: (_savedProgressRatio * dur.inMilliseconds).round(),
          );
          if (target.inSeconds > 3) {
            _initialResumeTarget = target;
            _player.seek(target);
            _resumeSafetyTimer = Timer(const Duration(seconds: 10), () {
              _initialResumeTarget = null;
            });
          }
        }
      }),
      _player.stream.buffer.listen((buf) {
        if (mounted) setState(() => _buffer = buf);
      }),
      _player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() => _isPlaying = playing);
          if (!playing && _initialResumeTarget == null && _position.inSeconds >= 4) {
            _saveCurrentProgress(_position);
          }
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => _isBuffering = buffering);

        if (buffering) {
          if (_isPlaying &&
              _currentStreamUrl.isNotEmpty &&
              !_currentStreamUrl.startsWith('/') &&
              !_currentStreamUrl.startsWith('file://')) {
            _bufferingWatchdogTimer?.cancel();
            _bufferingWatchdogTimer = Timer(const Duration(seconds: 8), () {
              if (mounted && _isBuffering) {
                _triggerAutoReconnect();
              }
            });
          }
        } else {
          _bufferingWatchdogTimer?.cancel();
          _bufferingWatchdogTimer = null;
          if (_isReconnecting) {
            setState(() {
              _isReconnecting = false;
              _reconnectAttempts = 0;
            });
          }
        }
      }),
      _player.stream.error.listen((err) {
        if (mounted && _currentStreamUrl.isNotEmpty && !_currentStreamUrl.startsWith('/') && !_currentStreamUrl.startsWith('file://')) {
          _triggerAutoReconnect();
        }
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

  Future<void> _triggerAutoReconnect() async {
    if (!mounted || _isReconnecting || _currentStreamUrl.isEmpty) return;
    if (_reconnectAttempts >= 3) {
      if (mounted) {
        setState(() {
          _isReconnecting = false;
          _isBuffering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Yayın bağlantısı koptu. Lütfen internetinizi kontrol edip tekrar deneyin.'),
            backgroundColor: AppColors.accentCrimson,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tekrar Dene',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _reconnectAttempts = 0);
                _triggerAutoReconnect();
              },
            ),
          ),
        );
      }
      return;
    }

    _reconnectAttempts++;
    setState(() => _isReconnecting = true);

    final savedPos = _position;
    await _player.stop();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      _initialResumeTarget = savedPos;
      final cubitState = context.read<PlayerCubit>().state;
      if (cubitState is PlayerReady) {
        _playStream(cubitState.selectedStream.url, cubitState.selectedSubtitle);
      }
    }
  }

  void _saveCurrentProgress(Duration pos) {
    if (pos.inSeconds < 4) return;
    String episodeThumb = '';
    String resolvedEpId = _currentEpisodeId;
    try {
      for (final ep in _seasonEpisodes) {
        if (ep.seasonNumber == _currentSeasonNumber &&
            ep.episodeNumber == _currentEpisodeNumber) {
          episodeThumb = ep.thumbnailUrl ?? '';
          if (ep.id.isNotEmpty && !ep.id.contains('_')) {
            resolvedEpId = ep.id;
            _currentEpisodeId = ep.id;
          }
          break;
        }
      }
    } catch (_) {}

    if (resolvedEpId.isEmpty || resolvedEpId.contains('_')) {
      try {
        final box = Hive.box('history');
        final saved = box.get(widget.animeId);
        if (saved is Map) {
          final sNum = int.tryParse(saved['seasonNumber']?.toString() ?? '');
          final epNum = int.tryParse(saved['episodeNumber']?.toString() ?? '');
          final sId = saved['episodeId']?.toString() ?? '';
          if (sNum == _currentSeasonNumber && epNum == _currentEpisodeNumber && sId.isNotEmpty && !sId.contains('_')) {
            resolvedEpId = sId;
            _currentEpisodeId = sId;
          }
        }
      } catch (_) {}
    }

    final finalEpId = (resolvedEpId.isNotEmpty && !resolvedEpId.contains('_'))
        ? resolvedEpId
        : _currentEpisodeNumber.toString();

    GetIt.I<PlayerRepository>().saveWatchProgress(
      animeId: widget.animeId,
      animeTitle: widget.animeTitle,
      posterUrl: widget.posterUrl,
      episodeId: finalEpId,
      episodeTitle: _currentEpisodeTitle,
      seasonNumber: _currentSeasonNumber,
      episodeNumber: _currentEpisodeNumber,
      position: pos,
      duration: _duration,
      episodeThumb: episodeThumb,
    );

    // Auto-scrobble to AniList & MyAnimeList when >= 85% watched
    if (_duration.inSeconds > 60 && !_hasScrobbledCurrentEpisode) {
      final ratio = pos.inMilliseconds / _duration.inMilliseconds;
      if (ratio >= 0.85) {
        _hasScrobbledCurrentEpisode = true;
        TrackingService.instance.scrobbleEpisode(
          animeTitle: widget.animeTitle,
          episode: _currentEpisodeNumber,
          isCompleted: ratio >= 0.95,
        );
      }
    }
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
          if (mounted) {
            setState(() {
              _seasonEpisodes = eps;
              for (final ep in eps) {
                if (ep.seasonNumber == _currentSeasonNumber &&
                    ep.episodeNumber == _currentEpisodeNumber) {
                  if (ep.id.isNotEmpty && !ep.id.contains('_')) {
                    _currentEpisodeId = ep.id;
                  }
                  break;
                }
              }
            });
          }
        },
      );
    } catch (_) {}
  }

  Future<void> _playStream(String url, SubtitleTrackEntity? subtitle) async {
    if (url.isEmpty || url == _currentStreamUrl) return;
    final lastPos = _position;
    _currentStreamUrl = url;
    _introSkipped = false;

    // Determine the target seek position
    Duration? seekTarget;
    if (lastPos.inSeconds > 5) {
      seekTarget = lastPos;
      _initialResumeTarget = lastPos;
    } else if (_initialSeekMs > 3000) {
      seekTarget = Duration(milliseconds: _initialSeekMs);
      _initialResumeTarget = seekTarget;
      _initialSeekMs = 0;
    } else if (_initialResumeTarget != null) {
      seekTarget = _initialResumeTarget;
    }

    final isLocal = url.startsWith('/') || url.startsWith('file://');
    final cleanPath = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;

    // Safety validation for local offline file
    if (isLocal) {
      final file = File(cleanPath);
      if (!file.existsSync() || file.lengthSync() < 100 * 1024) {
        debugPrint('⚠️ Local file missing or corrupt: $cleanPath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İndirilen dosya bulunamadı veya bozuk. Çevrimiçi kaynağa geçiliyor...'),
              backgroundColor: AppColors.accentCrimson,
            ),
          );
          // Fallback to online sources
          context.read<PlayerCubit>().loadVideoSources(
            animeId: widget.animeId,
            season: _currentSeasonNumber,
            episode: _currentEpisodeNumber,
          );
        }
        return;
      }
    }

    final media = isLocal
        ? Media(cleanPath, start: seekTarget)
        : Media(
            url,
            httpHeaders: {
              'Referer': ApiConstants.referer,
              'Origin': ApiConstants.origin,
              'User-Agent': ApiConstants.userAgent,
              'cf-control': ApiConstants.cfControl,
              'user-session': ApiConstants.userSession,
            },
            start: seekTarget,
          );

    await _player.open(media, play: true);
    await _player.play();

    if (subtitle != null && subtitle.url.isNotEmpty) {
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(
          subtitle.url,
          title: subtitle.name,
          language: subtitle.group,
        ),
      );
    }

    // Explicit seek after subtitle setup & media open
    if (seekTarget != null && seekTarget.inMilliseconds > 3000) {
      await _player.seek(seekTarget);
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

  void _switchEpisode(int season, int episode, String? title, {String? episodeId}) {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;

    int savedSeekMs = 0;
    double savedProgress = 0.0;
    String targetEpId = (episodeId != null && episodeId.isNotEmpty && !episodeId.contains('_'))
        ? episodeId
        : '';

    try {
      final box = Hive.box('history');
      final saved = box.get(widget.animeId);
      if (saved is Map) {
        final sNum = int.tryParse(saved['seasonNumber']?.toString() ?? '');
        final epNum = int.tryParse(saved['episodeNumber']?.toString() ?? '');
        if (sNum == season && epNum == episode) {
          if (targetEpId.isEmpty) {
            final sId = saved['episodeId']?.toString() ?? '';
            if (sId.isNotEmpty && !sId.contains('_')) {
              targetEpId = sId;
            }
          }
          var posMs = 0;
          final rawPos = saved['positionMs'] ?? saved['position_ms'];
          if (rawPos is num && rawPos > 0) {
            posMs = rawPos.toInt();
          } else {
            final rawSec = saved['currentTime'] ??
                saved['current_time'] ??
                saved['time'] ??
                saved['position'] ??
                saved['watchedTime'] ??
                saved['watched_time'];
            if (rawSec is num && rawSec > 0) {
              posMs = rawSec > 100000 ? rawSec.toInt() : (rawSec * 1000).round();
            }
          }

          final durationSec = (saved['duration'] as num?)?.toInt() ?? 0;
          final rawProg = (saved['progress'] as num?)?.toDouble() ?? 0.0;
          final progress = rawProg > 1.0 ? rawProg / 100.0 : rawProg;

          if (posMs <= 0 && progress > 0 && durationSec > 0) {
            posMs = (progress * durationSec * 1000).round();
          }

          if (progress > 0) {
            savedProgress = progress;
          }

          if (posMs > 3000) {
            savedSeekMs = posMs;
          }
        }
      }
    } catch (_) {}

    if (targetEpId.isEmpty && season == _currentSeasonNumber) {
      for (final ep in _seasonEpisodes) {
        if (ep.seasonNumber == season && ep.episodeNumber == episode) {
          if (ep.id.isNotEmpty && !ep.id.contains('_')) {
            targetEpId = ep.id;
          }
          break;
        }
      }
    }

    setState(() {
      _currentSeasonNumber = season;
      _currentEpisodeNumber = episode;
      _currentEpisodeTitle = title ?? 'Bölüm $episode';
      _currentEpisodeId = targetEpId;
      _position = Duration.zero;
      _positionNotifier.value = Duration.zero;
      _duration = Duration.zero;
      _currentStreamUrl = '';
      _isDismissedNextEpPrompt = false;
      _showControls = true;
      _initialSeekMs = savedSeekMs;
      _savedProgressRatio = savedProgress;
      _initialResumeTarget = savedSeekMs > 3000 ? Duration(milliseconds: savedSeekMs) : null;
      _introSkipped = false;
      _isDismissedIntroSong = false;
      _isIntroSongFadingOut = false;
      _lastIntroSongEpisodeKey = '';
      _hasScrobbledCurrentEpisode = false;
    });

    _introSongFadeTimer?.cancel();
    _introSongFadeTimer = null;
    _resumeSafetyTimer?.cancel();
    if (_initialResumeTarget != null) {
      _resumeSafetyTimer = Timer(const Duration(seconds: 10), () {
        _initialResumeTarget = null;
      });
    }

    _player.stop();
    _loadSeasonEpisodes();
    _resetControlsTimer();

    context.read<PlayerCubit>().loadVideoSources(
          animeId: widget.animeId,
          season: season,
          episode: episode,
        );
  }

  void _fetchIntroSongIfNeeded(BuildContext context, PlayerReady state) {
    final epKey = '${widget.animeId}_${_currentSeasonNumber}_$_currentEpisodeNumber';
    if (_lastIntroSongEpisodeKey == epKey) return;
    _lastIntroSongEpisodeKey = epKey;

    final resolvedEpId = _currentEpisodeId.isNotEmpty
        ? _currentEpisodeId
        : _currentEpisodeNumber.toString();

    context.read<PlayerCubit>().loadIntroSong(
          animeId: widget.animeId,
          episodeId: resolvedEpId,
          animeName: widget.animeTitle,
          season: _currentSeasonNumber,
          episode: _currentEpisodeNumber,
          introStart: state.sourceData.introStart,
          streamUrl: state.selectedStream.url,
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
            _switchEpisode(ep.seasonNumber, ep.episodeNumber, ep.title, episodeId: ep.id);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _saveCurrentProgress(_position);
    try {
      GetIt.I<SyncService>().syncNow();
    } catch (_) {}
    _bufferingWatchdogTimer?.cancel();
    _introSongFadeTimer?.cancel();
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.gameButtonA ||
                key == LogicalKeyboardKey.mediaPlayPause ||
                key == LogicalKeyboardKey.mediaPlay ||
                key == LogicalKeyboardKey.mediaPause) {
              _player.playOrPause();
              _toggleControls();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowLeft ||
                key == LogicalKeyboardKey.mediaRewind ||
                key == LogicalKeyboardKey.mediaTrackPrevious) {
              final target = _position - const Duration(seconds: 10);
              _player.seek(target < Duration.zero ? Duration.zero : target);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowRight ||
                key == LogicalKeyboardKey.mediaFastForward ||
                key == LogicalKeyboardKey.mediaTrackNext) {
              final target = _position + const Duration(seconds: 10);
              _player.seek(target > _duration ? _duration : target);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowUp) {
              final newVol = (_volume + 5.0).clamp(0.0, 100.0);
              setState(() => _volume = newVol);
              _player.setVolume(newVol);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowDown) {
              final newVol = (_volume - 5.0).clamp(0.0, 100.0);
              setState(() => _volume = newVol);
              _player.setVolume(newVol);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) async {
            await _player.stop();
            _saveCurrentProgress(_position);
            try {
              GetIt.I<SyncService>().syncNow();
            } catch (_) {}
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
                _fetchIntroSongIfNeeded(context, state);
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
            final isOffline = state.message.contains('SocketException') ||
                state.message.contains('Failed host lookup') ||
                state.message.contains('anizium') ||
                state.message.contains('HandshakeException');
            final cleanMessage = isOffline
                ? 'İnternet bağlantısı yok veya bölüm kaynağına ulaşılamadı.\nÇevrimdışı izlemek için bölümü önceden indirmiş olmanız gerekir.'
                : state.message;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.accentCrimson, size: 48),
                    const SizedBox(height: 12),
                    Text('Video Yüklenemedi', style: AppTypography.headlineMedium.copyWith(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      cleanMessage,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Geri Dön'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PlayerCubit>().loadVideoSources(
                                  animeId: widget.animeId,
                                  season: _currentSeasonNumber,
                                  episode: _currentEpisodeNumber,
                                );
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ],
                ),
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
                      _cancelInitialResume();
                      _player.seek(_position - Duration(seconds: seconds));
                      _resetControlsTimer();
                    },
                    onDoubleTapRight: (seconds) {
                      _cancelInitialResume();
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
                        color: Colors.black.withValues(alpha: (1.0 - _brightness) * 0.85),
                      ),
                    ),
                  ),

                // 3. Buffering / Auto-Reconnecting Indicator
                if (_isReconnecting)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(220),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                        border: Border.all(color: AppColors.primary, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Yeniden bağlanılıyor... ($_reconnectAttempts/3)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_isBuffering)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),

                // 4. Intro Song Badge (Bottom-Left)
                if (state.introSong != null &&
                    !_isDismissedIntroSong &&
                    introStart != null &&
                    introEnd != null)
                  ValueListenableBuilder<Duration>(
                    valueListenable: _positionNotifier,
                    builder: (context, pos, _) {
                      final currentSec = pos.inSeconds;
                      final isInsideIntro = currentSec >= introStart && currentSec < introEnd;
                      final isNearAfterIntro = currentSec >= introEnd && currentSec < introEnd + 4;

                      if (isInsideIntro) {
                        if (_isIntroSongFadingOut) {
                          _introSongFadeTimer?.cancel();
                          _introSongFadeTimer = null;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _isIntroSongFadingOut = false);
                          });
                        }
                      } else if (isNearAfterIntro) {
                        if (!_isIntroSongFadingOut && _introSongFadeTimer == null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _isIntroSongFadingOut = true);
                              _introSongFadeTimer = Timer(const Duration(milliseconds: 3000), () {
                                if (mounted) {
                                  setState(() => _isIntroSongFadingOut = false);
                                }
                              });
                            }
                          });
                        }
                      }

                      final shouldShow = isInsideIntro || (isNearAfterIntro && _isIntroSongFadingOut);
                      if (!shouldShow) return const SizedBox.shrink();

                      return Positioned(
                        bottom: _showControls ? 85 : 28,
                        left: 32,
                        child: IntroSongBadge(
                          song: state.introSong!,
                          isVisible: isInsideIntro,
                          isFadingOut: !isInsideIntro,
                          onDismissed: () {
                            setState(() => _isDismissedIntroSong = true);
                          },
                        ),
                      );
                    },
                  ),

                // 5. Skip Intro Button / Auto Skip Handler
                if (introStart != null && introEnd != null)
                  ValueListenableBuilder<Duration>(
                    valueListenable: _positionNotifier,
                    builder: (context, pos, _) {
                      final currentSec = pos.inSeconds;

                      // Auto Skip Intro trigger
                      if (_autoSkipIntro &&
                          !_introSkipped &&
                          currentSec >= introStart &&
                          currentSec <= introStart + 2) {
                        _introSkipped = true;
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
                        _cancelInitialResume();
                        _player.seek(_position + const Duration(seconds: 10));
                        _resetControlsTimer();
                      },
                      onSeekBackward: () {
                        _cancelInitialResume();
                        _player.seek(_position - const Duration(seconds: 10));
                        _resetControlsTimer();
                      },
                      onSeek: (val) {
                        _cancelInitialResume();
                        _player.seek(val);
                        _resetControlsTimer();
                      },
                      onSeekStart: () {
                        _cancelInitialResume();
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
      ),
    );
  }
}
