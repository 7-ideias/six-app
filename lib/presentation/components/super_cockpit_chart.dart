import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/admin_cockpit_snapshot.dart';
import '../../l10n/super_panel_texts.dart';
import '../utils/infrastructure_formatters.dart';
import 'web_dashboard_widgets.dart';

String cockpitTime(int epochMs) => DateFormat.Hm().format(
  DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true),
);

class SuperCockpitChart extends StatelessWidget {
  const SuperCockpitChart(this.snapshot, {super.key, required this.latency});
  final AdminCockpitSnapshot snapshot;
  final bool latency;

  @override
  Widget build(BuildContext context) {
    final points = snapshot.points;
    final names =
        latency
            ? ['p50', 'p95']
            : [superPanelText(context, 'total'), '4xx', '5xx'];
    final colors =
        latency
            ? [Colors.blue, Colors.deepPurple]
            : [Colors.blue, Colors.orange, Colors.red];
    final unit = latency ? 'ms' : '/min';
    final lines = <LineChartBarData>[];
    for (var series = 0; series < names.length; series++) {
      final spots = <FlSpot>[];
      for (final point in points) {
        final count =
            [point.total, point.clientErrors, point.serverErrors][series];
        final value =
            latency
                ? (series == 0 ? point.p50 : point.p95)?.toDouble()
                : point.observedMs > 0
                ? count * 60000 / point.observedMs
                : null;
        if (value == null || point.observedMs == 0) {
          if (spots.isNotEmpty && spots.last != FlSpot.nullSpot) {
            spots.add(FlSpot.nullSpot);
          }
        } else {
          // A partially observed interval starts at collection startup.
          spots.add(
            FlSpot(math.max(point.time, snapshot.startedAt).toDouble(), value),
          );
        }
      }
      if (spots.isNotEmpty && spots.last == FlSpot.nullSpot) spots.removeLast();
      lines.add(
        LineChartBarData(
          spots: spots,
          color: colors[series],
          barWidth: 2,
          dotData: FlDotData(
            show:
                points.length <= 16 ||
                spots.contains(FlSpot.nullSpot) ||
                spots.length == 1,
          ),
        ),
      );
    }
    final start = points.isEmpty ? snapshot.collectedAt : points.first.time;
    final restarted = snapshot.startedAt >= start;
    final noSamples = superPanelText(context, 'noSamples');
    return SixWebSectionCard(
      title: superPanelText(context, latency ? 'latency' : 'traffic'),
      icon: latency ? Icons.timer_outlined : Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 14,
            children: [
              for (var i = 0; i < names.length; i++)
                Text(
                  '● ${names[i]}',
                  style: TextStyle(
                    color: colors[i],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(unit),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child:
                lines.every((l) => l.spots.isEmpty)
                    ? Center(child: Text(noSamples))
                    : LineChart(
                      LineChartData(
                        minX: start.toDouble(),
                        maxX:
                            math
                                .max(start + 1, snapshot.collectedAt)
                                .toDouble(),
                        minY: 0,
                        maxY: math.max(
                          1.0,
                          lines
                                  .expand((l) => l.spots)
                                  .where((p) => p != FlSpot.nullSpot)
                                  .map((p) => p.y)
                                  .fold(0.0, math.max) *
                              1.12,
                        ),
                        lineBarsData: lines,
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(),
                          rightTitles: AxisTitles(),
                          bottomTitles: AxisTitles(),
                        ),
                        gridData: FlGridData(drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          verticalLines: [
                            if (restarted)
                              VerticalLine(
                                x: snapshot.startedAt.toDouble(),
                                color: Colors.grey,
                                strokeWidth: 1.5,
                                dashArray: [4, 4],
                              ),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems:
                                (spots) =>
                                    spots
                                        .map(
                                          (s) => LineTooltipItem(
                                            '${cockpitTime(s.x.toInt())}  ${names[s.barIndex]}  ${infrastructureNumber(context, s.y, decimals: 1)} $unit',
                                            const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                        .toList(),
                          ),
                        ),
                      ),
                    ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cockpitTime(start)} UTC'),
              Text(cockpitTime(snapshot.collectedAt)),
            ],
          ),
          if (restarted && lines.any((l) => l.spots.isNotEmpty))
            Text(superPanelText(context, 'gap')),
        ],
      ),
    );
  }
}
