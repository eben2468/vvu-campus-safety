// Riverpod providers for the admin dashboard.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../services/firestore_service.dart';
import '../../services/functions_service.dart';
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
    ref.watch(functionsProvider),
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
