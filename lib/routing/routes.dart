/// Route paths used with go_router.
abstract final class Routes {
  static const splash = '/';

  // Signed out
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Signed in but not linked to a VVU ID
  static const verifyId = '/verify-id';

  // Home for each role
  static const home = '/home'; // student / staff (mobile)
  static const officerHome = '/officer'; // officer, admin on mobile
  static const dashboard = '/dashboard'; // admin (web)
  static const useMobileApp = '/use-mobile-app'; // non-admins on web

  /// Routes a signed-out user may visit.
  static const signedOutRoutes = {login, register, forgotPassword};
}
