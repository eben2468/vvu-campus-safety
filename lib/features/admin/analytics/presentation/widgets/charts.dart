import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme.dart';
import '../../../data/analytics.dart';

/// A titled card with a fixed-height chart in it.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.height = 240,
  });

  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

/// Bars of incidents per category; SOS in red.
class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.counts});

  final List<MapEntry<String, int>> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const _NoData();
    return BarChart(
      BarChartData(
        barGroups: [
          for (final (i, entry) in counts.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.value.toDouble(),
                  width: 18,
                  color: entry.key == 'SOS'
                      ? AppColors.sosRed
                      : AppColors.vvuBlue,
                ),
              ],
            ),
        ],
        titlesData: _titles(
          reservedBottom: 56,
          bottom: (value) => counts[value.toInt()].key,
          angle: -0.6,
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Bars of incidents per week.
class WeeklyCountChart extends StatelessWidget {
  const WeeklyCountChart({super.key, required this.weeks});

  final List<WeekStats> weeks;

  @override
  Widget build(BuildContext context) {
    if (weeks.every((w) => w.count == 0)) return const _NoData();
    return BarChart(
      BarChartData(
        barGroups: [
          for (final (i, week) in weeks.indexed)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: week.count.toDouble(),
                  width: 14,
                  color: AppColors.vvuBlue,
                ),
              ],
            ),
        ],
        titlesData: _titles(
          reservedBottom: 32,
          bottom: (value) => _weekLabel(weeks, value),
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Average minutes from raised to accepted, week by week. Weeks where
/// nothing was accepted have no point.
class ResponseTrendChart extends StatelessWidget {
  const ResponseTrendChart({super.key, required this.weeks});

  final List<WeekStats> weeks;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (final (i, week) in weeks.indexed)
        if (week.avgResponse != null)
          FlSpot(i.toDouble(), week.avgResponse!.inSeconds / 60),
    ];
    if (spots.isEmpty) return const _NoData();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (weeks.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: AppColors.inProgress,
            barWidth: 3,
            dotData: const FlDotData(),
          ),
        ],
        titlesData: _titles(
          reservedBottom: 32,
          bottom: (value) => _weekLabel(weeks, value),
          leftSuffix: ' min',
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

/// Week labels like "3 Nov"; on long ranges only every few weeks.
String _weekLabel(List<WeekStats> weeks, double value) {
  final i = value.toInt();
  if (i < 0 || i >= weeks.length || value != i.toDouble()) return '';
  final step = (weeks.length / 8).ceil();
  return i % step == 0 ? DateFormat('d MMM').format(weeks[i].weekStart) : '';
}

FlTitlesData _titles({
  required double reservedBottom,
  required String Function(double value) bottom,
  double angle = 0,
  String leftSuffix = '',
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: leftSuffix.isEmpty ? 32 : 52,
        getTitlesWidget: (value, meta) {
          // Whole numbers only, so counts don't show "1.5".
          if (value != value.roundToDouble()) return const SizedBox.shrink();
          return SideTitleWidget(
            meta: meta,
            child: Text(
              '${value.toInt()}$leftSuffix',
              style: const TextStyle(fontSize: 11),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reservedBottom,
        interval: 1,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          angle: angle,
          child: Text(bottom(value), style: const TextStyle(fontSize: 11)),
        ),
      ),
    ),
  );
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('No incidents in this period.'));
}
