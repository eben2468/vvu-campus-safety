/// Numbers behind the analytics page (PRD §4.9): heatmap cells, chart
/// series and the CSV export. Pure functions over a list of incidents.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/incident.dart';

/// One square of the heatmap grid and how many incidents fell in it.
@immutable
class HeatCell {
  const HeatCell({
    required this.latitude,
    required this.longitude,
    required this.count,
  });

  /// Centre of the square.
  final double latitude;
  final double longitude;
  final int count;
}

/// Groups incident locations into squares about [cellMeters] wide. The
/// map draws a circle per square, darker for more incidents. (Google's
/// heatmap layer for the web is being retired, so the grid is drawn here.)
List<HeatCell> heatCells(
  Iterable<Incident> incidents, {
  double cellMeters = 50,
}) {
  // Degrees per metre: latitude is constant; longitude shrinks with cos(lat).
  const metersPerDegree = 111320.0;
  final counts = <(int, int), int>{};
  double? latStep;
  double? lngStep;
  for (final incident in incidents) {
    final point = incident.location ?? incident.lastLocation;
    if (point == null) continue;
    latStep ??= cellMeters / metersPerDegree;
    lngStep ??=
        cellMeters /
        (metersPerDegree * math.cos(point.latitude * math.pi / 180));
    final key = (
      (point.latitude / latStep).floor(),
      (point.longitude / lngStep).floor(),
    );
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return [
    for (final MapEntry(key: (row, col), value: count) in counts.entries)
      HeatCell(
        latitude: (row + 0.5) * latStep!,
        longitude: (col + 0.5) * lngStep!,
        count: count,
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
}

/// Incidents per category, most frequent first. SOS alerts count as "SOS".
List<MapEntry<String, int>> countByCategory(Iterable<Incident> incidents) {
  final counts = <String, int>{};
  for (final i in incidents) {
    final key = i.isSos ? 'SOS' : i.category;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

/// The Monday (00:00 UTC, i.e. Accra) that starts [time]'s week.
DateTime weekStart(DateTime time) {
  final utc = time.toUtc();
  final day = DateTime.utc(utc.year, utc.month, utc.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// One week's numbers for the charts.
@immutable
class WeekStats {
  const WeekStats({
    required this.weekStart,
    required this.count,
    this.avgResponse,
  });

  final DateTime weekStart;
  final int count;

  /// Mean time to accept; null if nothing was accepted that week.
  final Duration? avgResponse;
}

/// Incidents and average response time for every week from [from] to [to],
/// including weeks with no incidents so the chart's axis has no gaps.
List<WeekStats> weeklyStats(
  Iterable<Incident> incidents, {
  required DateTime from,
  required DateTime to,
}) {
  final byWeek = <DateTime, List<Incident>>{};
  for (final i in incidents) {
    if (i.createdAt == null) continue;
    byWeek.putIfAbsent(weekStart(i.createdAt!), () => []).add(i);
  }
  final weeks = <WeekStats>[];
  for (
    var week = weekStart(from);
    !week.isAfter(to);
    week = week.add(const Duration(days: 7))
  ) {
    final list = byWeek[week] ?? const <Incident>[];
    final seconds = [
      for (final i in list)
        if (i.responseSeconds != null) i.responseSeconds!,
    ];
    weeks.add(
      WeekStats(
        weekStart: week,
        count: list.length,
        avgResponse: seconds.isEmpty
            ? null
            : Duration(
                seconds: (seconds.reduce((a, b) => a + b) / seconds.length)
                    .round(),
              ),
      ),
    );
  }
  return weeks;
}

/// The incidents as a CSV file (one row each), for Excel or the thesis.
String incidentsCsv(Iterable<Incident> incidents) {
  const header = [
    'id',
    'raised (Africa/Accra)',
    'type',
    'category',
    'status',
    'reporter',
    'reporter phone',
    'place',
    'latitude',
    'longitude',
    'response seconds',
    'closed (Africa/Accra)',
    'cancelled by reporter',
    'description',
  ];
  final rows = [
    header,
    for (final i in incidents)
      [
        i.id,
        i.createdAt == null ? '' : formatDateTime(i.createdAt!),
        i.kind.name,
        i.category,
        i.status.value,
        i.reporterName,
        i.reporterPhone,
        i.locationLabel ?? '',
        i.location?.latitude.toString() ?? '',
        i.location?.longitude.toString() ?? '',
        i.responseSeconds?.toString() ?? '',
        i.resolvedAt == null ? '' : formatDateTime(i.resolvedAt!),
        i.cancelledByReporter ? 'yes' : 'no',
        i.description,
      ],
  ];
  return '${rows.map((r) => r.map(_csvField).join(',')).join('\r\n')}\r\n';
}

/// Quotes a field if it has a comma, quote or line break. Text starting
/// with =, +, - or @ gets an apostrophe so spreadsheets don't run it as a
/// formula; plain numbers (-0.122, +233…) are left alone.
String _csvField(String value) {
  var text = value;
  if (text.isNotEmpty &&
      '=+-@'.contains(text[0]) &&
      double.tryParse(text) == null) {
    text = "'$text";
  }
  if (text.contains(RegExp(r'[",\r\n]'))) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}
