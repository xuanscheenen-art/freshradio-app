import 'package:flutter_test/flutter_test.dart';
import 'package:freshradio_app/src/charts.dart';

void main() {
  test('parses a chart with movement', () {
    final c = Chart.fromJson(ChartPeriod.month, {
      'period': 'month',
      'label': 'november 2026',
      'items': [
        {'rank': 1, 'artist': 'Dave van Weerdinge', 'title': 'Trancelogic',
         'plays': 16, 'previousRank': 1, 'movement': 0},
        {'rank': 2, 'artist': 'Barbara Tucker', 'title': 'Beautiful People',
         'plays': 10, 'previousRank': null, 'movement': null},
        {'rank': 3, 'artist': 'Delerium', 'title': 'Silence',
         'plays': 9, 'previousRank': 2, 'movement': -1},
        {'rank': 4, 'artist': 'x', 'title': ''},
        'garbage',
      ],
    });
    expect(c.label, 'november 2026');
    expect(c.entries.length, 3);
    expect(c.entries[2].movement, -1);
    expect(c.entries[1].previousRank, isNull);
    expect(c.hasComparison, isTrue);
  });

  test('a first chart without history shows no movement', () {
    final c = Chart.fromJson(ChartPeriod.year, {
      'label': '2026',
      'items': [
        {'rank': 1, 'artist': 'A', 'title': 'B', 'plays': 43,
         'previousRank': null, 'movement': null},
      ],
    });
    expect(c.hasComparison, isFalse);
  });

  test('handles a missing items list', () {
    final c = Chart.fromJson(ChartPeriod.week, {'label': 'Week 48'});
    expect(c.entries, isEmpty);
  });
}
