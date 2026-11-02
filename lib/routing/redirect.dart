import '../core/constants.dart';
import '../features/auth/data/session.dart';
import 'routes.dart';

/// The home route for [role]. The web build is the admin dashboard only;
/// on mobile, admins share the officer screens (docs/ARCHITECTURE.md §1).
String homeFor(UserRole role, {required bool isWeb}) {
  if (isWeb) {
    return role == UserRole.admin ? Routes.dashboard : Routes.useMobileApp;
  }
  return role.isMember ? Routes.home : Routes.officerHome;
}

/// Where to send the user given their [session] and current [location].
/// Returns null to stay put. Kept free of Flutter so it is easy to test.
String? redirectFor(Session session, String location, {required bool isWeb}) {
  switch (session.status) {
    case SessionStatus.loading:
      // Stay put: the app starts on the splash screen, and a brief reload
      // (e.g. picking up new claims) shouldn't bounce the user around.
      return null;
    case SessionStatus.deactivated:
      // The app signs the user out; wait on the splash screen.
      return location == Routes.splash ? null : Routes.splash;
    case SessionStatus.signedOut:
      return Routes.signedOutRoutes.contains(location) ? null : Routes.login;
    case SessionStatus.unverified:
      // Registration is still running on /register; otherwise verify the ID.
      return location == Routes.register || location == Routes.verifyId
          ? null
          : Routes.verifyId;
    case SessionStatus.active:
      final home = homeFor(session.role!, isWeb: isWeb);
      return location.startsWith(home) ? null : home;
  }
}
