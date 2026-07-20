import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/weight_entry.dart';
import '../../l10n/strings.dart';

/// Line chart of weight over time with labeled axes:
/// x = date, y = weight in kg. Expects entries most-recent-first.
class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  const WeightChart({super.key, required this.entries});

  String _fmtShortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _fmtFullDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.bodySmall;

    // Oldest first for the x axis.
    final sorted = entries.reversed.toList();
    final spots = [
      for (final e in sorted)
        FlSpot(e.measuredAt.millisecondsSinceEpoch.toDouble(), e.weightKg),
    ];

    // With a single entry there is no x span: pad the axis by
    // one day on each side so the lone point renders centered.
    const dayMs = 24 * 60 * 60 * 1000.0;
    var minX = spots.first.x;
    var maxX = spots.last.x;
    if (minX == maxX) {
      minX -= dayMs;
      maxX += dayMs;
    }
    final xSpan = (maxX - minX).clamp(1, double.infinity).toDouble();

    final weights = spots.map((p) => p.y);
    var minY = weights.reduce((a, b) => a < b ? a : b);
    var maxY = weights.reduce((a, b) => a > b ? a : b);
    final ySpan = (maxY - minY).clamp(0.5, double.infinity).toDouble();
    // Breathing room above and below the line.
    minY = (minY - ySpan * 0.25).clamp(0, double.infinity);
    maxY = maxY + ySpan * 0.25;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: ySpan / 2,
          verticalInterval: xSpan / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: theme.colorScheme.outline),
            bottom: BorderSide(color: theme.colorScheme.outline),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: Text(s.weightKgLabel, style: labelStyle),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: ySpan / 2,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(1), style: labelStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(s.date, style: labelStyle),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: xSpan / 3,
              getTitlesWidget: (value, meta) {
                final d = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return SideTitleWidget(
                  meta: meta,
                  child: Text(_fmtShortDate(d), style: labelStyle),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => [
              for (final spot in touchedSpots)
                LineTooltipItem(
                  '${spot.y} kg\n${_fmtFullDate(DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()))}',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.surface,
                strokeWidth: 2.5,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.25), color.withOpacity(0.02)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
