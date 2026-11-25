import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'now_playing.dart';
import 'radio_audio_handler.dart';
import 'station_config.dart';
import 'track.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.audio, required this.nowPlaying});

  final RadioAudioHandler audio;
  final NowPlayingService nowPlaying;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  DateTime? _sleepAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.audio.error.addListener(_showError);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.error.removeListener(_showError);
    _cancelSleep();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh straight away when the app comes back to the foreground.
    if (state == AppLifecycleState.resumed) widget.nowPlaying.refresh();
  }

  void _showError() {
    final msg = widget.audio.error.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---- sleep timer -------------------------------------------------------

  void _setSleep(Duration? d) {
    _cancelSleep();
    if (d != null) {
      _sleepAt = DateTime.now().add(d);
      _sleepTimer = Timer(d, () {
        widget.audio.stop();
        _cancelSleep();
      });
      _sleepTicker =
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
    setState(() {});
  }

  void _cancelSleep() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = _sleepTicker = null;
    _sleepAt = null;
    if (mounted) setState(() {});
  }

  String? get _sleepLabel {
    final at = _sleepAt;
    if (at == null) return null;
    final left = at.difference(DateTime.now());
    if (left.isNegative) return null;
    final m = left.inMinutes;
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return 'Stopt over $m:$s';
  }

  Future<void> _openSleepSheet() async {
    final options = <String, Duration?>{
      '15 minuten': const Duration(minutes: 15),
      '30 minuten': const Duration(minutes: 30),
      '45 minuten': const Duration(minutes: 45),
      '1 uur': const Duration(hours: 1),
    };
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: station.surface,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Slaaptimer',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            for (final e in options.entries)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(e.key),
                onTap: () {
                  Navigator.pop(ctx);
                  _setSleep(e.value);
                },
              ),
            if (_sleepAt != null)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text('Uitzetten', style: TextStyle(color: station.live)),
                onTap: () {
                  Navigator.pop(ctx);
                  _setSleep(null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [station.backgroundTop, station.background],
            stops: const [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: ValueListenableBuilder<NowPlaying>(
            valueListenable: widget.nowPlaying.state,
            builder: (context, np, _) => LayoutBuilder(
              builder: (context, box) {
                final coverSize =
                    (box.maxWidth - 64).clamp(160.0, 340.0).toDouble();
                return RefreshIndicator(
                  onRefresh: widget.nowPlaying.refresh,
                  color: station.accent,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    children: [
                      const _Header(),
                      const SizedBox(height: 20),
                      Center(child: _Cover(np: np, size: coverSize)),
                      const SizedBox(height: 24),
                      _TrackInfo(track: np.current),
                      const SizedBox(height: 20),
                      _Controls(audio: widget.audio),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: _openSleepSheet,
                          icon: Icon(Icons.bedtime_outlined,
                              color: _sleepAt != null
                                  ? station.accent
                                  : station.muted),
                          label: Text(
                            _sleepLabel ?? 'Slaaptimer',
                            style: TextStyle(
                              color: _sleepAt != null
                                  ? station.accent
                                  : station.muted,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (np.history.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _History(tracks: np.history),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(station.logoAsset, height: 38),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: station.live.withValues(alpha: 0.16),
            border: Border.all(color: station.live.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: station.live, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('ON AIR',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ]),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.np, required this.size});

  final NowPlaying np;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = np.coverUrl;
    final radius = BorderRadius.circular(22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: station.accent.withValues(alpha: 0.28),
            blurRadius: 48,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: url == null
              ? const _CoverPlaceholder(key: ValueKey('placeholder'))
              : Image.network(
                  url,
                  key: ValueKey(url),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _CoverPlaceholder(),
                ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3B7A), Color(0xFF3B1A6E)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          station.name.replaceFirst(' ', '\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 10),
        Text('NON STOP DANCE',
            style: TextStyle(
                color: station.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3)),
      ]),
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.track});

  final Track? track;

  @override
  Widget build(BuildContext context) {
    final t = track;
    final showStation = t == null || t.isStationId;
    final title = showStation ? station.name : t.title;
    final artist = showStation
        ? station.tagline
        : (t.artist.isEmpty ? station.name : t.artist);
    return Column(
      children: [
        Text(
          'NU OP ${station.name.toUpperCase()}',
          style: TextStyle(
              color: station.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
        Text(title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(artist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: station.muted)),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.audio});

  final RadioAudioHandler audio;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: audio.playbackState,
      builder: (context, snap) {
        final s = snap.data;
        final playing = s?.playing ?? false;
        final loading = playing &&
            (s?.processingState == AudioProcessingState.loading ||
                s?.processingState == AudioProcessingState.buffering);
        return Center(
          child: Semantics(
            button: true,
            label: playing ? 'Stoppen' : 'Afspelen',
            child: GestureDetector(
              onTap: playing ? audio.stop : audio.play,
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [station.accent, station.accentDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: station.accent.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: Colors.white),
                      )
                    : Icon(
                        playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.tracks});

  final List<Track> tracks;

  String _time(DateTime? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Laatst gedraaid',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        for (final t in tracks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(
                width: 48,
                child: Text(_time(t.playedAt),
                    style: TextStyle(
                        color: station.muted,
                        fontSize: 13,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (t.artist.isNotEmpty)
                      Text(t.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: station.muted, fontSize: 13)),
                  ],
                ),
              ),
            ]),
          ),
      ],
    );
  }
}
