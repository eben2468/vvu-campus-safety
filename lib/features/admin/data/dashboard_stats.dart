import 'package:flutter/foundation.dart';

import '../../../models/incident.dart';
import '../../../models/incident_status.dart';

/// The live board's summary cards (PRD §4.8).
@immutable
class DashboardStats {
  const DashboardStats({
    required this.activeNow,
    required this.todayTotal,
    required this.resolvedToday,
    this.avgResponseToday,
    this.avgResponseWeek,
  });

  /// Works the numbers out from [active] (open incidents) and [lastWeek]
  /// (incidents raised in the last 7 days). "Today" is the calendar day in
  /// Africa/Accra, which is UTC.
  factory DashboardStats.from({
    required List<Incident> active,
    required List<Incident> lastWeek,
    required DateTime now,
  }) {
    final utc = now.toUtc();
    final startOfToday = DateTime.utc(utc.year, utc.month, utc.day);
    final weekAgo = utc.subtract(const Duration(days: 7));
    bool isToday(DateTime? time) =>
        time != null && !time.isBefore(startOfToday);

    final today = lastWeek.where((i) => isToday(i.createdAt)).toList();
    final week = lastWeek
        .where((i) => i.createdAt != null && !i.createdAt!.isBefore(weekAgo))
        .toList();

    return DashboardStats(
      activeNow: active.length,
      todayTotal: today.length,
      // Closed by security, not cancelled by the reporter ("I'm safe").
      resolvedToday: lastWeek
          .where(
            (i) =>
                i.status == IncidentStatus.resolved &&
                !i.cancelledByReporter &&
                isToday(i.resolvedAt),
          )
          .length,
      avgResponseToday: averageResponse(today),
      avgResponseWeek: averageResponse(week),
    );
  }

  final int activeNow;
  final int todayTotal;
  final int resolvedToday;

  /// Mean time from raised to accepted; null if nothing was accepted.
  final Duration? avgResponseToday;
  final Duration? avgResponseWeek;

  /// Mean `responseSeconds` of the incidents that have one.
  static Duration? averageResponse(Iterable<Incident> incidents) {
    final seconds = [
      for (final i in incidents)
        if (i.responseSeconds != null) i.responseSeconds!,
    ];
    if (seconds.isEmpty) return null;
    final mean = seconds.reduce((a, b) => a + b) / seconds.length;
    return Duration(seconds: mean.round());
  }
}
