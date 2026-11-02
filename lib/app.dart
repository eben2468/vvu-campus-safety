import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session.dart';
import 'features/auth/providers.dart';
import 'features/notifications/providers.dart';
import 'routing/router.dart';
import 'services/messaging_service.dart';

/// Root widget: theme, go_router, push setup and app-wide session rules.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Tapping a push opens the matching screen; the router's redirect still
    // applies, so a user can't open a page their role doesn't allow.
    ref
        .read(messagingServiceProvider)
        .init(
          onOpen: (data) => ref.read(routerProvider).go(routeForPush(data)),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Keep this device registered for push while someone is signed in.
    ref.watch(pushRegistrationProvider);

    // An admin can deactivate an account at any time: sign out straight away
    // and tell the user why on the login screen.
    ref.listen(sessionProvider, (_, next) {
      if (next.status == SessionStatus.deactivated) {
        ref
            .read(signOutNoticeProvider.notifier)
            .show(accountDeactivatedMessage);
        ref.read(authRepositoryProvider).signOut();
      }
    });

    // adminSetRole sets the new claim, then updates `users.role`. When the
    // profile's role stops matching the token, fetch a fresh token so the
    // new role (and home screen) applies straight away.
    ref.listen(sessionProvider, (_, next) {
      final profileRole = next.profile?.role;
      if (next.status == SessionStatus.active &&
          profileRole != null &&
          profileRole != next.role) {
        ref.read(authRepositoryProvider).refreshUser().ignore();
      }
    });

    return MaterialApp.router(
      title: 'VVU Campus Safety',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
