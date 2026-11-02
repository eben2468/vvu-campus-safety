import 'package:flutter/material.dart';

import 'widgets/signed_in_scaffold.dart';

/// Shown on the web to anyone who isn't an admin: the web build is the
/// security dashboard only.
class UseMobileAppScreen extends StatelessWidget {
  const UseMobileAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignedInScaffold(
      title: 'VVU Campus Safety',
      body: InfoPanel(
        icon: Icons.phone_android,
        heading: 'Please use the mobile app',
        message:
            'This website is the dashboard for security administrators. '
            'Students, staff and officers should use the VVU Campus Safety '
            'app on their Android phone.',
      ),
    );
  }
}
