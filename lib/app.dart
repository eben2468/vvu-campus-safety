import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/session.dart';
import 'features/auth/providers.dart';
import 'routing/router.dart';

/// Root widget: theme + go_router.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return MaterialApp.router(
      title: 'VVU Campus Safety',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
