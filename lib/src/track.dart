/// One entry from the station's play history.
class Track {
  const Track({
    required this.artist,
    required this.title,
    required this.raw,
    this.playedAt,
    this.isStationId = false,
  });

  final String artist;
  final String title;

  /// The metadata string exactly as the stream sent it.
  final String raw;
  final DateTime? playedAt;

  /// True for jingles and station IDs ("Fresh Radio - Day starts here").
  final bool isStationId;

  /// Parses Shoutcast metadata of the form "Artist - Title".
  factory Track.fromMetadata(
    String raw, {
    DateTime? playedAt,
    List<String> stationIdArtists = const [],
  }) {
    final text = raw.trim();
    final sep = text.indexOf(' - ');
    final artist = sep > 0 ? text.substring(0, sep).trim() : '';
    final title = sep > 0 ? text.substring(sep + 3).trim() : text;
    final isId = stationIdArtists
        .any((s) => s.toLowerCase() == artist.toLowerCase());
    return Track(
      artist: artist,
      title: title,
      raw: text,
      playedAt: playedAt,
      isStationId: isId,
    );
  }

  /// Parses the Shoutcast v2 `played?type=json` response (newest first).
  static List<Track> listFromPlayedJson(
    List<dynamic> json, {
    List<String> stationIdArtists = const [],
  }) {
    final out = <Track>[];
    for (final item in json) {
      if (item is! Map) continue;
      final title = item['title'];
      if (title is! String || title.trim().isEmpty) continue;
      final ts = item['playedat'];
      out.add(Track.fromMetadata(
        title,
        playedAt: ts is int
            ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
            : null,
        stationIdArtists: stationIdArtists,
      ));
    }
    return out;
  }

  /// "Song (Radio Mix) [Remastered]" -> "Song", for cover art search.
  String get searchTitle =>
      title.replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]'), '').trim();

  /// "Artist feat. Other" -> "Artist", for cover art search.
  String get searchArtist => artist
      .split(RegExp(r'\s+(feat\.?|ft\.?|featuring|&|vs\.?|x)\s+',
          caseSensitive: false))
      .first
      .trim();

  @override
  bool operator ==(Object other) => other is Track && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;
}
