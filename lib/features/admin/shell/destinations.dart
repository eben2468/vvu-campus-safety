import 'package:flutter/material.dart';

import '../../../routing/routes.dart';

/// One page in the dashboard's side navigation.
typedef Destination = ({
  String route,
  String label,
  IconData icon,
  String group,
});

const List<Destination> destinations = [
  (
    route: Routes.dashboard,
    label: 'Live board',
    icon: Icons.space_dashboard_outlined,
    group: 'Operations',
  ),
  (
    route: Routes.dashboardIncidents,
    label: 'Incidents',
    icon: Icons.report_outlined,
    group: 'Operations',
  ),
  (
    route: Routes.dashboardAnalytics,
    label: 'Analytics',
    icon: Icons.insights_outlined,
    group: 'Operations',
  ),
  (
    route: Routes.dashboardUsers,
    label: 'Users',
    icon: Icons.group_outlined,
    group: 'People',
  ),
  (
    route: Routes.dashboardRoster,
    label: 'ID roster',
    icon: Icons.badge_outlined,
    group: 'People',
  ),
  (
    route: Routes.dashboardAnnouncements,
    label: 'Announcements',
    icon: Icons.campaign_outlined,
    group: 'People',
  ),
  (
    route: Routes.dashboardSettings,
    label: 'Settings',
    icon: Icons.tune,
    group: 'System',
  ),
  (
    route: Routes.dashboardAuditLog,
    label: 'Audit log',
    icon: Icons.history,
    group: 'System',
  ),
];

/// The destination for [location]. The live board is '/dashboard', a
/// prefix of every other page, so the longest match wins.
Destination destinationFor(String location) {
  final index = destinations.lastIndexWhere(
    (d) => location.startsWith(d.route),
  );
  return destinations[index < 0 ? 0 : index];
}
