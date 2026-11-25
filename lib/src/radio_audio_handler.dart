import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'station_config.dart';
import 'track.dart';

/// Plays the live stream and keeps the lock screen, notification and
/// headphone controls in sync.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler(this.config) {
    _init();
  }

  final StationConfig config;
  final AudioPlayer _player = AudioPlayer();

  /// Set when the stream cannot be started; cleared on the next attempt.
  final ValueNotifier<String?> error = ValueNotifier(null);

  MediaItem get _stationItem => MediaItem(
        id: config.streamUrl,
        title: config.name,
        artist: config.tagline,
        album: config.name,
      );

  Future<void> _init() async {
    mediaItem.add(_stationItem);
    _broadcast();
    _player.playbackEventStream.listen(
      (_) => _broadcast(),
      onError: (Object e, StackTrace st) => _fail(e),
    );
    _player.playingStream.listen((_) => _broadcast());
    // Some players keep reporting "buffering" on endless live streams while
    // audio is in fact coming through, so also watch the position move.
    _player.positionStream.listen((pos) {
      if (pos > _lastPosition) _lastProgressAt = DateTime.now();
      _lastPosition = pos;
      final state = _processingState();
      if (state != playbackState.value.processingState) _broadcast();
    });
    Timer.periodic(const Duration(seconds: 1), (_) {
      if (_player.playing &&
          _processingState() != playbackState.value.processingState) {
        _broadcast();
      }
    });

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    // Pause when headphones are unplugged.
    session.becomingNoisyEventStream.listen((_) => stop());
  }

  void _fail(Object e) {
    debugPrint('Playback error: $e');
    error.value = 'De stream is nu niet bereikbaar. Probeer het zo opnieuw.';
    _player.stop();
  }

  Duration _lastPosition = Duration.zero;
  DateTime? _lastProgressAt;

  AudioProcessingState _processingState() {
    final s = _player.processingState;
    final recentlyProgressed = _lastProgressAt != null &&
        DateTime.now().difference(_lastProgressAt!) <
            const Duration(seconds: 2);
    if (s == ProcessingState.buffering && recentlyProgressed) {
      return AudioProcessingState.ready;
    }
    return const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.idle,
    }[s]!;
  }

  void _broadcast() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [playing ? MediaControl.stop : MediaControl.play],
      androidCompactActionIndices: const [0],
      systemActions: const {},
      processingState: _processingState(),
      playing: playing,
    ));
  }

  @override
  Future<void> play() async {
    error.value = null;
    _lastPosition = Duration.zero;
    _lastProgressAt = null;
    try {
      // Always reconnect so the listener hears the live broadcast,
      // not an old buffer.
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(config.streamUrl)),
        // Loading starts with play(); waiting for a preload can hang on
        // endless live streams.
        preload: false,
      );
      unawaited(_player.play().catchError(_fail));
    } catch (e) {
      _fail(e);
    }
  }

  /// A live stream cannot be paused; pausing stops it.
  @override
  Future<void> pause() => stop();

  @override
  Future<void> stop() async {
    await _player.stop();
    _broadcast();
  }

  /// Shows the current song on the lock screen and in the car.
  void showTrack(Track? track, String? coverUrl) {
    if (track == null || track.isStationId) {
      mediaItem.add(_stationItem);
      return;
    }
    mediaItem.add(MediaItem(
      id: config.streamUrl,
      title: track.title,
      artist: track.artist.isEmpty ? config.name : track.artist,
      album: config.name,
      artUri: coverUrl == null ? null : Uri.parse(coverUrl),
    ));
  }
}
