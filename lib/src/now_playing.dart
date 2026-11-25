import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'station_config.dart';
import 'track.dart';

/// What is on air right now, plus the last few songs.
@immutable
class NowPlaying {
  const NowPlaying({this.current, this.history = const [], this.coverUrl});

  /// The newest song. Null until the first successful poll.
  final Track? current;

  /// Earlier songs, newest first, without jingles.
  final List<Track> history;

  /// Album art for [current], if one was found.
  final String? coverUrl;

  NowPlaying copyWith({String? coverUrl}) =>
      NowPlaying(current: current, history: history, coverUrl: coverUrl);
}

/// Polls the station's play history and looks up album art.
class NowPlayingService {
  NowPlayingService({
    required this.config,
    http.Client? client,
    this.interval = const Duration(seconds: 15),
    this.historyLength = 5,
  }) : _client = client ?? http.Client();

  final StationConfig config;
  final Duration interval;
  final int historyLength;
  final http.Client _client;

  final ValueNotifier<NowPlaying> state = ValueNotifier(const NowPlaying());
  final Map<String, String?> _coverCache = {};
  Timer? _timer;

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    try {
      final res = await _client
          .get(Uri.parse(config.historyUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List) return;
      final all = Track.listFromPlayedJson(decoded,
          stationIdArtists: config.stationIdArtists);
      if (all.isEmpty) return;

      final current = all.first;
      final history = all
          .skip(1)
          .where((t) => !t.isStationId)
          .take(historyLength)
          .toList();

      final previous = state.value;
      final sameSong = previous.current == current;
      state.value = NowPlaying(
        current: current,
        history: history,
        coverUrl: sameSong ? previous.coverUrl : null,
      );
      if (!sameSong && !current.isStationId) {
        final cover = await coverFor(current);
        if (state.value.current == current) {
          state.value = state.value.copyWith(coverUrl: cover);
        }
      }
    } catch (e) {
      debugPrint('Now playing refresh failed: $e');
    }
  }

  /// Album art via the public iTunes Search API, cached per song.
  Future<String?> coverFor(Track track) async {
    if (track.isStationId || track.artist.isEmpty) return null;
    final key = track.raw.toLowerCase();
    if (_coverCache.containsKey(key)) return _coverCache[key];

    String? url;
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': '${track.searchArtist} ${track.searchTitle}',
        'media': 'music',
        'entity': 'song',
        'limit': '5',
        'country': 'NL',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final results = (jsonDecode(utf8.decode(res.bodyBytes))
                as Map<String, dynamic>)['results'] as List<dynamic>? ??
            const [];
        final wanted = track.searchArtist.toLowerCase();
        Map<String, dynamic>? best;
        for (final r in results.cast<Map<String, dynamic>>()) {
          final artist = (r['artistName'] as String? ?? '').toLowerCase();
          if (artist.contains(wanted) || wanted.contains(artist)) {
            best = r;
            break;
          }
        }
        final art = best?['artworkUrl100'] as String?;
        url = art?.replaceAll('100x100bb', '600x600bb');
      }
    } catch (e) {
      debugPrint('Cover lookup failed: $e');
    }
    _coverCache[key] = url;
    return url;
  }

  void dispose() {
    stop();
    _client.close();
    state.dispose();
  }
}
