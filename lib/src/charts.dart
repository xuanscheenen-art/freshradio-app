import 'dart:convert';

import 'package:http/http.dart' as http;

/// The chart periods the station's website offers.
enum ChartPeriod {
  week('week', 'Week', 'Top 30'),
  month('month', 'Maand', 'Top 30'),
  year('year', 'Jaar', 'Top 500');

  const ChartPeriod(this.apiValue, this.label, this.size);

  final String apiValue;
  final String label;
  final String size;
}

class ChartEntry {
  const ChartEntry({
    required this.rank,
    required this.artist,
    required this.title,
    required this.plays,
    this.previousRank,
    this.movement,
  });

  final int rank;
  final String artist;
  final String title;
  final int plays;

  /// Null when the track was not in the previous chart.
  final int? previousRank;

  /// Places gained (positive) or lost (negative) since the previous chart.
  final int? movement;

  factory ChartEntry.fromJson(Map<String, dynamic> j) => ChartEntry(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        artist: (j['artist'] as String? ?? '').trim(),
        title: (j['title'] as String? ?? '').trim(),
        plays: (j['plays'] as num?)?.toInt() ?? 0,
        previousRank: (j['previousRank'] as num?)?.toInt(),
        movement: (j['movement'] as num?)?.toInt(),
      );
}

class Chart {
  const Chart({required this.period, required this.label, required this.entries});

  final ChartPeriod period;

  /// For example "Week 48 • 23 nov – 24 nov 2026".
  final String label;
  final List<ChartEntry> entries;

  /// False for a chart that has no previous chart to compare with yet,
  /// so the app does not mark every track as new.
  bool get hasComparison => entries.any((e) => e.previousRank != null);

  factory Chart.fromJson(ChartPeriod period, Map<String, dynamic> j) {
    final items = j['items'];
    return Chart(
      period: period,
      label: (j['label'] as String? ?? '').trim(),
      entries: items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(ChartEntry.fromJson)
              .where((e) => e.title.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

/// Reads the airplay charts from the station's website.
class ChartsService {
  ChartsService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Endpoint without the period, e.g.
  /// `https://freshradio.nl/wp-json/fresh-radio/v1/charts`.
  final String baseUrl;
  final http.Client _client;
  final Map<ChartPeriod, Chart> _cache = {};

  Chart? cached(ChartPeriod p) => _cache[p];

  Future<Chart> load(ChartPeriod period) async {
    final uri =
        Uri.parse(baseUrl).replace(queryParameters: {'period': period.apiValue});
    final res = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Charts: HTTP ${res.statusCode}');
    }
    final chart = Chart.fromJson(
        period, jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    _cache[period] = chart;
    return chart;
  }
}
