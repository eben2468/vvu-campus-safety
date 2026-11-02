import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/features/auth/data/session.dart';
import 'package:vvu_campus_safety/features/notifications/providers.dart';
import 'package:vvu_campus_safety/routing/redirect.dart';
import 'package:vvu_campus_safety/routing/routes.dart';

Session active(UserRole role) =>
    Session(status: SessionStatus.active, role: role);

void main() {
  group('signed out', () {
    test('is sent to login from protected routes', () {
      expect(
        redirectFor(Session.signedOut, Routes.home, isWeb: false),
        Routes.login,
      );
      expect(
        redirectFor(Session.signedOut, Routes.splash, isWeb: true),
        Routes.login,
      );
    });

    test('may stay on login, register and forgot password', () {
      for (final route in Routes.signedOutRoutes) {
        expect(redirectFor(Session.signedOut, route, isWeb: false), isNull);
      }
    });
  });

  test('loading never redirects', () {
    expect(redirectFor(Session.loading, Routes.register, isWeb: false), isNull);
    expect(redirectFor(Session.loading, Routes.splash, isWeb: false), isNull);
  });

  test('unverified users finish registration or verify their ID', () {
    expect(
      redirectFor(Session.unverified, Routes.register, isWeb: false),
      isNull,
    );
    expect(
      redirectFor(Session.unverified, Routes.login, isWeb: false),
      Routes.verifyId,
    );
    expect(
      redirectFor(Session.unverified, Routes.home, isWeb: false),
      Routes.verifyId,
    );
  });

  test('deactivated users wait on the splash screen while signed out', () {
    expect(
      redirectFor(Session.deactivated, Routes.home, isWeb: false),
      Routes.splash,
    );
  });

  group('mobile homes by role', () {
    test('students and staff go to home', () {
      expect(
        redirectFor(active(UserRole.student), Routes.login, isWeb: false),
        Routes.home,
      );
      expect(
        redirectFor(active(UserRole.staff), Routes.splash, isWeb: false),
        Routes.home,
      );
    });

    test('officers and admins go to the officer home', () {
      expect(
        redirectFor(active(UserRole.officer), Routes.login, isWeb: false),
        Routes.officerHome,
      );
      expect(
        redirectFor(active(UserRole.admin), Routes.login, isWeb: false),
        Routes.officerHome,
      );
    });

    test('a student cannot open the officer screens', () {
      expect(
        redirectFor(active(UserRole.student), Routes.officerHome, isWeb: false),
        Routes.home,
      );
    });

    test('users already on their home stay put', () {
      expect(
        redirectFor(active(UserRole.student), Routes.home, isWeb: false),
        isNull,
      );
    });
  });

  group('web', () {
    test('admins go to the dashboard', () {
      expect(
        redirectFor(active(UserRole.admin), Routes.login, isWeb: true),
        Routes.dashboard,
      );
    });

    test('everyone else is told to use the mobile app', () {
      for (final role in [UserRole.student, UserRole.staff, UserRole.officer]) {
        expect(
          redirectFor(active(role), Routes.dashboard, isWeb: true),
          Routes.useMobileApp,
        );
      }
    });

    test('admins can open every dashboard page; officers cannot', () {
      for (final page in [
        Routes.dashboardIncidents,
        Routes.dashboardUsers,
        Routes.dashboardRoster,
        Routes.dashboardAnnouncements,
      ]) {
        expect(redirectFor(active(UserRole.admin), page, isWeb: true), isNull);
        expect(
          redirectFor(active(UserRole.officer), page, isWeb: true),
          Routes.useMobileApp,
        );
      }
    });
  });

  group('TokenClaims.canUseApp', () {
    test('members need a verified ID', () {
      expect(
        const TokenClaims(uid: 'a', role: UserRole.student).canUseApp,
        isFalse,
      );
      expect(
        const TokenClaims(
          uid: 'a',
          role: UserRole.student,
          verified: true,
        ).canUseApp,
        isTrue,
      );
    });

    test('officers only need a role', () {
      expect(
        const TokenClaims(uid: 'a', role: UserRole.officer).canUseApp,
        isTrue,
      );
      expect(const TokenClaims(uid: 'a').canUseApp, isFalse);
    });
  });

  group('first run on a phone', () {
    test('shows the permissions screen before home', () {
      expect(
        redirectFor(
          active(UserRole.student),
          Routes.login,
          isWeb: false,
          onboardingDone: false,
        ),
        Routes.welcome,
      );
      expect(
        redirectFor(
          active(UserRole.officer),
          Routes.welcome,
          isWeb: false,
          onboardingDone: false,
        ),
        isNull,
      );
    });

    test('leaves the permissions screen once done', () {
      expect(
        redirectFor(active(UserRole.student), Routes.welcome, isWeb: false),
        Routes.home,
      );
    });

    test('is skipped on the web dashboard', () {
      expect(
        redirectFor(
          active(UserRole.admin),
          Routes.login,
          isWeb: true,
          onboardingDone: false,
        ),
        Routes.dashboard,
      );
    });
  });

  test('officers can open alert pages', () {
    expect(
      redirectFor(
        active(UserRole.officer),
        Routes.incidentAlert('s1'),
        isWeb: false,
      ),
      isNull,
    );
    expect(
      redirectFor(
        active(UserRole.student),
        Routes.incidentAlert('s1'),
        isWeb: false,
      ),
      Routes.home,
    );
  });

  test('push taps open the right screen', () {
    expect(
      routeForPush({'type': 'sos', 'incidentId': 's1'}),
      Routes.incidentAlert('s1'),
    );
    expect(
      routeForPush({'type': 'status', 'incidentId': 's1'}),
      Routes.reportDetail('s1'),
    );
    expect(
      routeForPush({'type': 'message', 'incidentId': 's1'}),
      Routes.chat('s1'),
    );
    expect(routeForPush({'type': 'announcement'}), Routes.announcements);
    expect(routeForPush({}), Routes.splash);
  });

  test('chat and announcements are open to every phone user', () {
    for (final role in UserRole.values) {
      expect(
        redirectFor(active(role), Routes.chat('s1'), isWeb: false),
        isNull,
      );
      expect(
        redirectFor(active(role), Routes.announcements, isWeb: false),
        isNull,
      );
    }
    expect(
      redirectFor(active(UserRole.admin), Routes.chat('s1'), isWeb: true),
      Routes.dashboard,
    );
  });
}
