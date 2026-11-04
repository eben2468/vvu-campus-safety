// Riverpod providers for the admin dashboard.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/audit_log_entry.dart';
import '../../models/incident.dart';
import '../../models/roster_entry.dart';
import '../../services/api_client.dart';
import '../../services/firestore_service.dart';
import '../officer/providers.dart';
import 'data/admin_repository.dart';
import 'data/dashboard_repository.dart';
import 'data/dashboard_stats.dart';
import 'data/incident_filter.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(firestoreProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    ref.watch(firestoreProvider),
    ref.watch(apiClientProvider),
  );
});

/// Incidents raised in the last 7 days, for the summary cards. The window
/// is fixed when the dashboard opens; reloading the page moves it on.
final lastWeekIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  final since = DateTime.now().toUtc().subtract(const Duration(days: 7));
  return ref.watch(dashboardRepositoryProvider).watchSince(since);
});

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  return DashboardStats.from(
    active: ref.watch(activeIncidentsProvider).value ?? const [],
    lastWeek: ref.watch(lastWeekIncidentsProvider).value ?? const [],
    now: DateTime.now(),
  );
});

final recentActivityProvider = StreamProvider<List<ActivityItem>>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchRecentActivity();
});

final recentIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchRecent();
});

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(
      IncidentFilterNotifier.new,
    );

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void set(IncidentFilter filter) => state = filter;
}

/// The incidents table: recent incidents that pass the current filter.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  return ref.watch(recentIncidentsProvider).whenData(filter.apply);
});

final userGroupProvider = NotifierProvider<UserGroupNotifier, UserGroup>(
  UserGroupNotifier.new,
);

class UserGroupNotifier extends Notifier<UserGroup> {
  @override
  UserGroup build() => UserGroup.security;

  void set(UserGroup group) => state = group;
}

final usersProvider = StreamProvider<List<AppUser>>((ref) {
  final group = ref.watch(userGroupProvider);
  return ref.watch(adminRepositoryProvider).watchUsers(group);
});

final rosterProvider = StreamProvider<List<RosterEntry>>((ref) {
  return ref.watch(adminRepositoryProvider).watchRoster();
});

/// The analytics page's date range (whole Accra days, [to] inclusive) and
/// category; null category means all.
typedef AnalyticsFilter = ({DateTime from, DateTime to, String? category});

final analyticsFilterProvider =
    NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter>(
      AnalyticsFilterNotifier.new,
    );

class AnalyticsFilterNotifier extends Notifier<AnalyticsFilter> {
  /// The last 30 days, today included.
  @override
  AnalyticsFilter build() {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return (
      from: today.subtract(const Duration(days: 29)),
      to: today,
      category: null,
    );
  }

  void setRange(DateTime from, DateTime to) =>
      state = (from: from, to: to, category: state.category);

  void setCategory(String? category) =>
      state = (from: state.from, to: state.to, category: category);
}

/// Incidents in the analytics date range. Re-queries only when the dates
/// change; the category is applied in [analyticsIncidentsProvider].
final _incidentsInRangeProvider = StreamProvider<List<Incident>>((ref) {
  final (from, to) = ref.watch(
    analyticsFilterProvider.select((f) => (f.from, f.to)),
  );
  return ref
      .watch(dashboardRepositoryProvider)
      .watchBetween(from, to.add(const Duration(days: 1)));
});

final analyticsIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final category = ref.watch(analyticsFilterProvider.select((f) => f.category));
  return ref
      .watch(_incidentsInRangeProvider)
      .whenData(
        (list) => category == null
            ? list
            : list
                  .where(
                    (i) => category == 'SOS' ? i.isSos : i.category == category,
                  )
                  .toList(),
      );
});

final auditLogsProvider = StreamProvider<List<AuditLogEntry>>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchAuditLogs();
});
