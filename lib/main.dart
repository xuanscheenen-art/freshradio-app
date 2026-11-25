import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app_shell.dart';
import 'src/charts.dart';
import 'src/now_playing.dart';
import 'src/radio_audio_handler.dart';
import 'src/station_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audio = await AudioService.init(
    builder: () => RadioAudioHandler(station),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'nl.freshradio.app.playback',
      androidNotificationChannelName: 'Radio afspelen',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final nowPlaying = NowPlayingService(config: station)..start();
  // Keep the lock screen in step with what is on air.
  nowPlaying.state.addListener(() {
    final s = nowPlaying.state.value;
    audio.showTrack(s.current, s.coverUrl);
  });

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: station.background,
  ));

  final chartsUrl = station.chartsUrl;
  final charts = chartsUrl == null ? null : ChartsService(baseUrl: chartsUrl);

  runApp(RadioApp(audio: audio, nowPlaying: nowPlaying, charts: charts));
}

class RadioApp extends StatelessWidget {
  const RadioApp({
    super.key,
    required this.audio,
    required this.nowPlaying,
    this.charts,
  });

  final RadioAudioHandler audio;
  final NowPlayingService nowPlaying;
  final ChartsService? charts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: station.name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: station.background,
        colorScheme: ColorScheme.dark(
          primary: station.accent,
          secondary: station.accentAlt,
          surface: station.surface,
          onSurface: station.text,
        ),
        useMaterial3: true,
      ),
      home: AppShell(audio: audio, nowPlaying: nowPlaying, charts: charts),
    );
  }
}
