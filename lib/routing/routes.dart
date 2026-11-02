/// Route paths used with go_router.
abstract final class Routes {
  static const splash = '/';

  // Signed out
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Signed in but not linked to a VVU ID
  static const verifyId = '/verify-id';

  // First run on a phone: explain and ask for permissions
  static const welcome = '/welcome';

  // Home for each role
  static const home = '/home'; // student / staff (mobile)
  static const officerHome = '/officer'; // officer, admin on mobile
  static const dashboard = '/dashboard'; // admin (web)
  static const useMobileApp = '/use-mobile-app'; // non-admins on web

  // Member pages (under /home so the role redirect allows them)
  static const report = '/home/report';
  static const myReports = '/home/reports';
  static const reportDetailPattern = '/home/reports/:incidentId';
  static String reportDetail(String incidentId) => '/home/reports/$incidentId';

  /// Officer view of one alert.
  static const incidentAlertPattern = '/officer/incident/:incidentId';
  static String incidentAlert(String incidentId) =>
      '/officer/incident/$incidentId';

  /// Routes a signed-out user may visit.
  static const signedOutRoutes = {login, register, forgotPassword};
}
