import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'charts.dart';
import 'charts_screen.dart';
import 'home_screen.dart';
import 'now_playing.dart';
import 'radio_audio_handler.dart';
import 'station_config.dart';

/// Bottom tabs: Live and (when the station has charts) Charts.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.audio,
    required this.nowPlaying,
    this.charts,
  });

  final RadioAudioHandler audio;
  final NowPlayingService nowPlaying;
  final ChartsService? charts;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final home = HomeScreen(audio: widget.audio, nowPlaying: widget.nowPlaying);
    final charts = widget.charts;
    if (charts == null) return home;

    return Scaffold(
      backgroundColor: station.background,
      body: IndexedStack(
        index: _tab,
        children: [home, ChartsScreen(service: charts)],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_tab != 0)
            _MiniPlayer(
              audio: widget.audio,
              nowPlaying: widget.nowPlaying,
              onOpen: () => setState(() => _tab = 0),
            ),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            backgroundColor: station.background,
            indicatorColor: station.accent.withValues(alpha: 0.18),
            height: 64,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.radio_outlined),
                selectedIcon: Icon(Icons.radio),
                label: 'Live',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Charts',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small player bar shown on the other tabs.
class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.audio,
    required this.nowPlaying,
    required this.onOpen,
  });

  final RadioAudioHandler audio;
  final NowPlayingService nowPlaying;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: station.surface,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: station.accent.withValues(alpha: 0.25)),
            ),
          ),
          child: Row(children: [
            ValueListenableBuilder<NowPlaying>(
              valueListenable: nowPlaying.state,
              builder: (_, np, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: np.coverUrl == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              station.accentDeep,
                              station.accentAlt,
                            ]),
                          ),
                          child: const Icon(Icons.graphic_eq, size: 22),
                        )
                      : Image.network(np.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ValueListenableBuilder<NowPlaying>(
                valueListenable: nowPlaying.state,
                builder: (_, np, _) {
                  final t = np.current;
                  final station0 = t == null || t.isStationId;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(station0 ? station.name : t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                          station0
                              ? station.tagline
                              : (t.artist.isEmpty ? station.name : t.artist),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: station.muted, fontSize: 13)),
                    ],
                  );
                },
              ),
            ),
            StreamBuilder<PlaybackState>(
              stream: audio.playbackState,
              builder: (_, snap) {
                final s = snap.data;
                final playing = s?.playing ?? false;
                final loading = playing &&
                    (s?.processingState == AudioProcessingState.loading ||
                        s?.processingState == AudioProcessingState.buffering);
                return IconButton(
                  iconSize: 36,
                  color: station.accent,
                  tooltip: playing ? 'Stoppen' : 'Afspelen',
                  onPressed: playing ? audio.stop : audio.play,
                  icon: loading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 3))
                      : Icon(playing
                          ? Icons.stop_circle_rounded
                          : Icons.play_circle_fill_rounded),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}
