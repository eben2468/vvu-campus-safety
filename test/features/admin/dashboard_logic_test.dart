import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/core/utils/formatters.dart';
import 'package:vvu_campus_safety/features/admin/data/dashboard_stats.dart';
import 'package:vvu_campus_safety/features/admin/data/incident_filter.dart';
import 'package:vvu_campus_safety/features/admin/data/new_sos_tracker.dart';
import 'package:vvu_campus_safety/models/incident.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

Incident incident(
  String id, {
  IncidentKind kind = IncidentKind.sos,
  IncidentStatus status = IncidentStatus.alerted,
  String category = sosCategory,
  DateTime? createdAt,
  DateTime? resolvedAt,
  int? responseSeconds,
  bool cancelled = false,
  String reporterName = 'Kwame Mensah',
}) => Incident(
  id: id,
  kind: kind,
  status: status,
  reporterId: 'kwame',
  reporterName: reporterName,
  category: category,
  createdAt: createdAt,
  resolvedAt: resolvedAt,
  responseSeconds: responseSeconds,
  active: !status.isClosed,
  cancelledByReporter: cancelled,
);

void main() {
  final now = DateTime.utc(2026, 11, 2, 15);
  final today = DateTime.utc(2026, 11, 2, 9);
  final yesterday = DateTime.utc(2026, 11, 1, 22);
  final tenDaysAgo = DateTime.utc(2026, 10, 23);

  group('DashboardStats', () {
    test('counts today in Accra time and averages response times', () {
      final lastWeek = [
        incident('a', createdAt: today, responseSeconds: 60),
        incident(
          'b',
          status: IncidentStatus.resolved,
          createdAt: today,
          resolvedAt: today,
          responseSeconds: 120,
        ),
        incident(
          'c',
          status: IncidentStatus.resolved,
          createdAt: yesterday,
          resolvedAt: today,
          responseSeconds: 300,
        ),
        // Cancelled by the reporter: not "resolved" by security.
        incident(
          'd',
          status: IncidentStatus.resolved,
          createdAt: today,
          resolvedAt: today,
          cancelled: true,
        ),
        incident('old', createdAt: tenDaysAgo, responseSeconds: 9999),
      ];
      final stats = DashboardStats.from(
        active: [lastWeek.first],
        lastWeek: lastWeek,
        now: now,
      );
      expect(stats.activeNow, 1);
      expect(stats.todayTotal, 3);
      expect(stats.resolvedToday, 2);
      expect(stats.avgResponseToday, const Duration(seconds: 90));
      expect(stats.avgResponseWeek, const Duration(seconds: 160));
    });

    test('has no average when nothing was accepted', () {
      final stats = DashboardStats.from(active: [], lastWeek: [], now: now);
      expect(stats.avgResponseToday, isNull);
      expect(stats.todayTotal, 0);
    });
  });

  group('NewSosTracker', () {
    test('treats the first list as already known', () {
      final tracker = NewSosTracker();
      expect(tracker.update([incident('a')]), isEmpty);
    });

    test('reports SOS alerts that arrive later and are still waiting', () {
      final tracker = NewSosTracker()..update([incident('a')]);
      final arrived = tracker.update([
        incident('a'),
        incident('b', status: IncidentStatus.newIncident),
        incident('c', status: IncidentStatus.accepted),
        incident('r', kind: IncidentKind.report, category: 'Theft'),
      ]);
      expect(arrived.map((i) => i.id), ['b']);
      // Seen once: no second alarm.
      expect(tracker.update([incident('b')]), isEmpty);
    });
  });

  group('IncidentFilter', () {
    final list = [
      incident('sos1', reporterName: 'Abena Owusu'),
      incident(
        'theft1',
        kind: IncidentKind.report,
        category: 'Theft',
        status: IncidentStatus.resolved,
      ),
    ];

    test('filters by open or closed, type and category', () {
      List<String> ids(IncidentFilter f) =>
          f.apply(list).map((i) => i.id).toList();
      expect(ids(const IncidentFilter()), ['sos1', 'theft1']);
      expect(ids(const IncidentFilter(status: StatusFilter.open)), ['sos1']);
      expect(ids(const IncidentFilter(status: StatusFilter.closed)), [
        'theft1',
      ]);
      expect(ids(const IncidentFilter(kind: IncidentKind.report)), ['theft1']);
      expect(ids(const IncidentFilter(category: 'Theft')), ['theft1']);
    });

    test('searches the reporter name and status, ignoring case', () {
      expect(
        const IncidentFilter(search: 'abena').apply(list).single.id,
        'sos1',
      );
      expect(
        const IncidentFilter(search: 'Resolved').apply(list).single.id,
        'theft1',
      );
    });

    test('copyWith can clear a filter', () {
      const filter = IncidentFilter(category: 'Theft');
      expect(filter.copyWith(category: () => null).category, isNull);
      expect(filter.copyWith(search: 'x').category, 'Theft');
    });
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 45)), '45 s');
    expect(formatDuration(const Duration(minutes: 3)), '3 min');
    expect(
      formatDuration(const Duration(minutes: 3, seconds: 20)),
      '3 min 20 s',
    );
    expect(formatDuration(const Duration(hours: 1, minutes: 5)), '1 h 5 min');
    expect(formatDuration(const Duration(hours: 2)), '2 h');
  });
}
