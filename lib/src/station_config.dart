import 'package:flutter/material.dart';

/// Everything that is specific to one radio station.
///
/// To build an app for another station, copy this file's values
/// (name, stream, history URL, colours, logo) and leave the rest of the
/// code untouched.
class StationConfig {
  const StationConfig({
    required this.name,
    required this.tagline,
    required this.streamUrl,
    required this.historyUrl,
    this.chartsUrl,
    required this.websiteUrl,
    required this.logoAsset,
    required this.stationIdArtists,
    required this.background,
    required this.backgroundTop,
    required this.surface,
    required this.accent,
    required this.accentDeep,
    required this.accentAlt,
    required this.text,
    required this.muted,
    required this.live,
  });

  final String name;
  final String tagline;

  /// Direct audio stream (Shoutcast/Icecast, MP3 or AAC).
  final String streamUrl;

  /// Shoutcast v2 "played" endpoint returning JSON, newest first.
  final String historyUrl;

  /// Airplay charts endpoint (without `?period=`). Null hides the Charts tab.
  final String? chartsUrl;

  final String websiteUrl;
  final String logoAsset;

  /// "Artist" names that mark a jingle or station ID instead of a song.
  final List<String> stationIdArtists;

  final Color background;
  final Color backgroundTop;
  final Color surface;
  final Color accent;
  final Color accentDeep;
  final Color accentAlt;
  final Color text;
  final Color muted;
  final Color live;
}

const freshRadio = StationConfig(
  name: 'Fresh Radio',
  tagline: 'Non Stop The Best in Dance',
  streamUrl: 'https://server7.radio-streams.net/proxy/jcikurvb/stream',
  historyUrl:
      'https://server7.radio-streams.net/proxy/jcikurvb/played?sid=1&type=json',
  chartsUrl: 'https://freshradio.nl/wp-json/fresh-radio/v1/charts',
  websiteUrl: 'https://freshradio.nl',
  logoAsset: 'assets/logo.png',
  stationIdArtists: ['Fresh Radio'],
  // Colours taken from the freshradio.nl theme.
  background: Color(0xFF031024),
  backgroundTop: Color(0xFF071B3B),
  surface: Color(0xFF071A3A),
  accent: Color(0xFF00C9FF),
  accentDeep: Color(0xFF1583FF),
  accentAlt: Color(0xFFB55CFF),
  text: Color(0xFFF7FBFF),
  muted: Color(0xFFA8BED9),
  live: Color(0xFFFF3548),
);

/// The station this build of the app is for.
const station = freshRadio;
