import 'package:flutter/material.dart';

import 'charts.dart';
import 'station_config.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key, required this.service});

  final ChartsService service;

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartPeriod _period = ChartPeriod.week;
  Chart? _chart;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    final period = _period;
    final cached = widget.service.cached(period);
    setState(() {
      _chart = cached;
      _error = null;
      _loading = cached == null || force;
    });
    if (cached != null && !force) return;
    try {
      final chart = await widget.service.load(period);
      if (!mounted || period != _period) return;
      setState(() {
        _chart = chart;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || period != _period) return;
      setState(() {
        _loading = false;
        _error = 'De charts konden niet worden geladen. '
            'Controleer je internetverbinding en trek omlaag om het opnieuw '
            'te proberen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = _chart;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: station.accent,
        onRefresh: () => _load(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              sliver: SliverList.list(children: [
                const Text('Charts',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('De meest gedraaide tracks op ${station.name}',
                    style: TextStyle(color: station.muted)),
                const SizedBox(height: 16),
                SegmentedButton<ChartPeriod>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in ChartPeriod.values)
                      ButtonSegment(value: p, label: Text(p.label)),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) {
                    setState(() => _period = s.first);
                    _load();
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? station.accentDeep
                            : station.surface),
                    foregroundColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? Colors.white
                            : station.muted),
                    side: WidgetStatePropertyAll(BorderSide(
                        color: station.accent.withValues(alpha: 0.3))),
                  ),
                ),
                const SizedBox(height: 12),
                if (chart != null && chart.label.isNotEmpty)
                  Text('${_period.size} · ${chart.label}',
                      style: TextStyle(
                          color: station.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
              ]),
            ),
            if (_loading && chart == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && chart == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: station.muted)),
                  ),
                ),
              )
            else if (chart != null && chart.entries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Nog geen tracks in deze chart.',
                      style: TextStyle(color: station.muted)),
                ),
              )
            else if (chart != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: chart.entries.length,
                  itemBuilder: (_, i) => _ChartRow(
                    entry: chart.entries[i],
                    showMovement: chart.hasComparison,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartRow extends StatelessWidget {
  const _ChartRow({required this.entry, required this.showMovement});

  final ChartEntry entry;
  final bool showMovement;

  Widget _movement() {
    final m = entry.movement;
    final TextStyle base =
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w800);
    if (entry.previousRank == null) {
      return Text('NEW', style: base.copyWith(color: station.accentAlt));
    }
    if (m != null && m > 0) {
      return Text('▲$m', style: base.copyWith(color: const Color(0xFF2FE39A)));
    }
    if (m != null && m < 0) {
      return Text('▼${-m}', style: base.copyWith(color: station.live));
    }
    return Text('●', style: base.copyWith(color: station.muted));
  }

  @override
  Widget build(BuildContext context) {
    final top3 = entry.rank <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: station.accent.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Text('${entry.rank}',
                style: TextStyle(
                  fontSize: top3 ? 20 : 17,
                  fontWeight: FontWeight.w800,
                  color: top3 ? station.accent : station.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
            if (showMovement) _movement(),
          ]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(entry.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: station.muted, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('${entry.plays}×',
            style: TextStyle(
                color: station.muted,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}
