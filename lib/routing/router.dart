import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/analytics/presentation/analytics_screen.dart';
import '../features/admin/announcements/presentation/admin_announcements_screen.dart';
import '../features/admin/audit/presentation/audit_log_screen.dart';
import '../features/admin/incidents/presentation/incidents_screen.dart';
import '../features/admin/live_board/presentation/live_board_screen.dart';
import '../features/admin/roster/presentation/roster_import_screen.dart';
import '../features/admin/settings/presentation/settings_screen.dart';
import '../features/admin/shell/admin_shell.dart';
import '../features/admin/users/presentation/users_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/permissions_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/use_mobile_app_screen.dart';
import '../features/auth/presentation/verify_id_screen.dart';
import '../features/auth/providers.dart';
import '../features/contacts/presentation/contacts_screen.dart';
import '../features/incidents/presentation/chat_screen.dart';
import '../features/incidents/presentation/incident_detail_screen.dart';
import '../features/incidents/presentation/my_reports_screen.dart';
import '../features/incidents/presentation/report_screen.dart';
import '../features/notifications/presentation/announcements_screen.dart';
import '../features/officer/presentation/alert_detail_screen.dart';
import '../features/officer/presentation/officer_home_screen.dart';
import '../features/sos/presentation/home_screen.dart';
import '../services/preferences_service.dart';
import 'redirect.dart';
import 'routes.dart';

/// App router. Re-runs [redirectFor] whenever the session or onboarding
/// state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.listen(onboardingDoneProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => redirectFor(
      ref.read(sessionProvider),
      state.matchedLocation,
      isWeb: kIsWeb,
      onboardingDone: ref.read(onboardingDoneProvider),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: Routes.verifyId, builder: (_, _) => const VerifyIdScreen()),
      GoRoute(
        path: Routes.welcome,
        builder: (_, _) => const PermissionsScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: Routes.report, builder: (_, _) => const ReportScreen()),
      GoRoute(path: Routes.contacts, builder: (_, _) => const ContactsScreen()),
      GoRoute(
        path: Routes.myReports,
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(
        path: Routes.reportDetailPattern,
        builder: (_, state) => IncidentDetailScreen(
          incidentId: state.pathParameters['incidentId']!,
        ),
      ),
      GoRoute(
        path: Routes.officerHome,
        builder: (_, _) => const OfficerHomeScreen(),
      ),
      GoRoute(
        path: Routes.incidentAlertPattern,
        builder: (_, state) =>
            AlertDetailScreen(incidentId: state.pathParameters['incidentId']!),
      ),
      GoRoute(
        path: Routes.announcements,
        builder: (_, _) => const AnnouncementsScreen(),
      ),
      GoRoute(
        path: Routes.chatPattern,
        builder: (_, state) =>
            ChatScreen(incidentId: state.pathParameters['incidentId']!),
      ),
      // Admin dashboard (web): every page shares the side navigation.
      ShellRoute(
        builder: (_, state, child) =>
            AdminShell(location: state.matchedLocation, child: child),
        routes: [
          _dashboardPage(Routes.dashboard, const LiveBoardScreen()),
          _dashboardPage(Routes.dashboardIncidents, const IncidentsScreen()),
          _dashboardPage(Routes.dashboardUsers, const UsersScreen()),
          _dashboardPage(Routes.dashboardRoster, const RosterImportScreen()),
          _dashboardPage(
            Routes.dashboardAnnouncements,
            const AdminAnnouncementsScreen(),
          ),
          _dashboardPage(Routes.dashboardAnalytics, const AnalyticsScreen()),
          _dashboardPage(Routes.dashboardSettings, const SettingsScreen()),
          _dashboardPage(Routes.dashboardAuditLog, const AuditLogScreen()),
        ],
      ),
      GoRoute(
        path: Routes.useMobileApp,
        builder: (_, _) => const UseMobileAppScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Dashboard pages switch without an animation, like tabs.
GoRoute _dashboardPage(String path, Widget page) => GoRoute(
  path: path,
  pageBuilder: (_, state) => NoTransitionPage(key: state.pageKey, child: page),
);
