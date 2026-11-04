// Pumps the real admin dashboard (shell + pages) with sample data and no
// Firebase, for the page smoke tests and the screenshot tool.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/core/theme.dart';
import 'package:vvu_campus_safety/features/admin/analytics/presentation/analytics_screen.dart';
import 'package:vvu_campus_safety/features/admin/announcements/presentation/admin_announcements_screen.dart';
import 'package:vvu_campus_safety/features/admin/audit/presentation/audit_log_screen.dart';
import 'package:vvu_campus_safety/features/admin/data/admin_repository.dart';
import 'package:vvu_campus_safety/features/admin/data/dashboard_repository.dart';
import 'package:vvu_campus_safety/features/admin/incidents/presentation/incidents_screen.dart';
import 'package:vvu_campus_safety/features/admin/live_board/presentation/live_board_screen.dart';
import 'package:vvu_campus_safety/features/admin/providers.dart';
import 'package:vvu_campus_safety/features/admin/roster/presentation/roster_screen.dart';
import 'package:vvu_campus_safety/features/admin/settings/presentation/settings_screen.dart';
import 'package:vvu_campus_safety/features/admin/shell/admin_shell.dart';
import 'package:vvu_campus_safety/features/admin/users/presentation/users_screen.dart';
import 'package:vvu_campus_safety/features/auth/data/session.dart';
import 'package:vvu_campus_safety/features/auth/providers.dart';
import 'package:vvu_campus_safety/features/notifications/providers.dart';
import 'package:vvu_campus_safety/features/officer/providers.dart';
import 'package:vvu_campus_safety/features/sos/providers.dart';
import 'package:vvu_campus_safety/models/announcement.dart';
import 'package:vvu_campus_safety/models/app_settings.dart';
import 'package:vvu_campus_safety/models/app_user.dart';
import 'package:vvu_campus_safety/models/audit_log_entry.dart';
import 'package:vvu_campus_safety/models/incident.dart';
import 'package:vvu_campus_safety/models/incident_event.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';
import 'package:vvu_campus_safety/models/roster_entry.dart';
import 'package:vvu_campus_safety/routing/routes.dart';

/// Every dashboard page, by route.
final dashboardPages = <String, Widget>{
  Routes.dashboard: const LiveBoardScreen(),
  Routes.dashboardIncidents: const IncidentsScreen(),
  Routes.dashboardAnalytics: const AnalyticsScreen(),
  Routes.dashboardUsers: const UsersScreen(),
  Routes.dashboardRoster: const RosterScreen(),
  Routes.dashboardAnnouncements: const AdminAnnouncementsScreen(),
  Routes.dashboardSettings: const SettingsScreen(),
  Routes.dashboardAuditLog: const AuditLogScreen(),
};

final _now = DateTime.now().toUtc();
DateTime _ago(Duration d) => _now.subtract(d);
const _centre = (lat: 5.793, lng: -0.122);
GeoPoint _near(double dLat, double dLng) =>
    GeoPoint(_centre.lat + dLat, _centre.lng + dLng);

const admin = AppUser(
  uid: 'admin-1',
  fullName: 'Grace Ofori',
  email: 'admin@vvu.test',
  phone: '+233200000001',
  role: UserRole.admin,
  verified: true,
);

final sampleUsers = [
  admin,
  const AppUser(
    uid: 'officer-1',
    fullName: 'Samuel Tetteh',
    email: 'officer@vvu.test',
    phone: '+233200000002',
    role: UserRole.officer,
    onDuty: true,
  ),
  const AppUser(
    uid: 'officer-2',
    fullName: 'Abena Kyei',
    email: 'abena.kyei@vvu.test',
    phone: '+233200000003',
    role: UserRole.officer,
  ),
  const AppUser(
    uid: 'student-1',
    fullName: 'Kwame Mensah',
    email: 'kwame@example.com',
    phone: '+233548811774',
    idNumber: '223IT0100001',
    role: UserRole.student,
    falseAlarmCount: 1,
  ),
  const AppUser(
    uid: 'student-2',
    fullName: 'Efia Owusu',
    email: 'efia@example.com',
    phone: '+233241234567',
    idNumber: '224BA5796846',
    role: UserRole.student,
    deactivated: true,
  ),
];

final sampleRoster = [
  const RosterEntry(
    idNumber: '223IT0100001',
    fullName: 'Kwame Mensah',
    type: 'student',
    department: 'Information Technology',
    claimedBy: 'student-1',
  ),
  const RosterEntry(
    idNumber: '224BA0300042',
    fullName: 'Kofi Asante',
    type: 'student',
    active: false,
  ),
  for (var i = 0; i < 60; i++)
    RosterEntry(
      idNumber: 'STF${i.toString().padLeft(4, '0')}',
      fullName: 'Staff Member $i',
      type: 'staff',
      department: 'Registry',
      importedAt: _now,
    ),
];

final sampleIncidents = [
  Incident(
    id: 'i1',
    kind: IncidentKind.sos,
    status: IncidentStatus.alerted,
    reporterId: 'student-1',
    reporterName: 'Kwame Mensah',
    reporterPhone: '+233548811774',
    location: _near(0.002, -0.002),
    locationLabel: 'Hostels',
    createdAt: _ago(const Duration(minutes: 3)),
  ),
  Incident(
    id: 'i2',
    kind: IncidentKind.report,
    status: IncidentStatus.accepted,
    category: 'Theft',
    description: 'My laptop was taken from the library.',
    reporterId: 'student-2',
    reporterName: 'Efia Owusu',
    location: _near(0, 0.001),
    locationLabel: 'Lecture halls',
    createdAt: _ago(const Duration(minutes: 40)),
    acknowledgedAt: _ago(const Duration(minutes: 35)),
    responseSeconds: 300,
  ),
  for (var i = 0; i < 18; i++)
    Incident(
      id: 'past-$i',
      kind: i % 4 == 0 ? IncidentKind.sos : IncidentKind.report,
      status: i % 6 == 5 ? IncidentStatus.falseAlarm : IncidentStatus.resolved,
      category: i % 4 == 0
          ? sosCategory
          : ['Theft', 'Harassment', 'Medical', 'Suspicious activity'][i % 4],
      reporterId: 'student-1',
      reporterName: i.isEven ? 'Kwame Mensah' : 'Yaw Darko',
      location: _near(0.002 - (i % 3) * 0.002, -0.002 + (i % 5) * 0.001),
      locationLabel: ['Hostels', 'Main gate', 'Admin block'][i % 3],
      createdAt: _ago(Duration(days: 1 + i, hours: i)),
      responseSeconds: 60 + i * 37,
      active: false,
    ),
];

final _openIncidents = sampleIncidents.where((i) => i.active).toList();

final _activity = [
  for (final (i, type) in [
    IncidentEventType.created,
    IncidentEventType.alerted,
    IncidentEventType.accepted,
    IncidentEventType.onScene,
    IncidentEventType.resolved,
  ].indexed)
    ActivityItem(
      incidentId: 'i1',
      event: IncidentEvent(
        id: 'e$i',
        type: type,
        actorId: 'officer-1',
        actorName: 'Samuel Tetteh',
        text: switch (type) {
          IncidentEventType.created => 'SOS raised by Kwame Mensah',
          IncidentEventType.alerted => '3 officers alerted',
          IncidentEventType.accepted => 'Samuel Tetteh accepted',
          IncidentEventType.onScene => 'Samuel Tetteh is on scene',
          _ => 'Resolved: student escorted to the clinic',
        },
        timestamp: _ago(Duration(minutes: 3 + i * 9)),
      ),
    ),
];

final _audit = [
  AuditLogEntry(
    id: 'a1',
    actorId: 'admin-1',
    action: 'user_created',
    target: 'officer-2',
    details: const {'role': 'officer'},
    timestamp: _ago(const Duration(hours: 2)),
  ),
  AuditLogEntry(
    id: 'a2',
    actorId: 'admin-1',
    action: 'settings_updated',
    target: 'app',
    details: const {
      'fields': ['sosCountdownSec'],
    },
    timestamp: _ago(const Duration(days: 1)),
  ),
  AuditLogEntry(
    id: 'a3',
    actorId: 'admin-1',
    action: 'user_deactivated',
    target: 'student-2',
    timestamp: _ago(const Duration(days: 2)),
  ),
];

final _announcements = [
  Announcement(
    id: 'n1',
    title: 'Gate closes at 11 pm',
    body: 'The main gate closes at 11 pm during exams. Use the side gate.',
    createdAt: _ago(const Duration(hours: 5)),
  ),
  Announcement(
    id: 'n2',
    title: 'Fire drill on Friday',
    body: 'A fire drill will take place at the hostels at 10 am.',
    audience: AnnouncementAudience.students,
    createdAt: _ago(const Duration(days: 3)),
  ),
];

final sampleSettings = AppSettings(
  securityPhone: '+233302000000',
  campusBoundary: [
    _near(0.004, -0.004),
    _near(0.004, 0.004),
    _near(-0.004, 0.004),
    _near(-0.004, -0.004),
  ],
  zones: [
    CampusZone(name: 'Hostels', center: _near(0.002, -0.002), radiusM: 150),
  ],
);

class FakeDashboardRepository extends Fake implements DashboardRepository {
  FakeDashboardRepository({required this.empty});

  final bool empty;
  List<Incident> get _incidents => empty ? const [] : sampleIncidents;

  @override
  Stream<List<Incident>> watchSince(DateTime since) => Stream.value(_incidents);

  @override
  Stream<List<Incident>> watchRecent({int limit = 300}) =>
      Stream.value(_incidents);

  @override
  Stream<List<Incident>> watchBetween(DateTime from, DateTime to) =>
      Stream.value(_incidents);

  @override
  Stream<List<AuditLogEntry>> watchAuditLogs({int limit = 200}) =>
      Stream.value(empty ? const [] : _audit);

  @override
  Stream<List<ActivityItem>> watchRecentActivity({int limit = 15}) =>
      Stream.value(empty ? const [] : _activity);
}

class FakeAdminRepository extends Fake implements AdminRepository {
  FakeAdminRepository({required this.empty});

  final bool empty;

  @override
  Stream<List<AppUser>> watchUsers(UserGroup group) => Stream.value(
    empty
        ? const []
        : sampleUsers.where((u) => group.roles.contains(u.role)).toList(),
  );

  @override
  Stream<List<RosterEntry>> watchRoster() =>
      Stream.value(empty ? const [] : sampleRoster);
}

/// Wraps the whole app, so a test can capture it as an image.
final screenshotKey = GlobalKey();

/// Shows [route] in the dashboard shell at [size] (logical pixels).
/// [empty] uses no data, to check the empty states.
Future<void> pumpDashboard(
  WidgetTester tester,
  String route, {
  Size size = const Size(1440, 900),
  bool empty = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: route,
    routes: [
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          for (final page in dashboardPages.entries)
            GoRoute(path: page.key, builder: (_, _) => page.value),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(
          const Session(
            status: SessionStatus.active,
            role: UserRole.admin,
            profile: admin,
            emailVerified: true,
          ),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          FakeDashboardRepository(empty: empty),
        ),
        adminRepositoryProvider.overrideWithValue(
          FakeAdminRepository(empty: empty),
        ),
        activeIncidentsProvider.overrideWith(
          (ref) => Stream.value(empty ? const [] : _openIncidents),
        ),
        appSettingsProvider.overrideWith((ref) => Stream.value(sampleSettings)),
        announcementsProvider.overrideWith(
          (ref) => Stream.value(empty ? const [] : _announcements),
        ),
      ],
      child: RepaintBoundary(
        key: screenshotKey,
        child: MaterialApp.router(
          theme: AppTheme.dashboard(),
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        ),
      ),
    ),
  );
  // Let the streams deliver; maps keep animating tiles, so don't settle.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
