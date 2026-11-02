import 'package:flutter/material.dart';

import 'email_verification_banner.dart';
import 'sign_out_button.dart';

/// Layout for signed-in screens: app bar with sign-out, the email
/// confirmation banner, then [body].
class SignedInScaffold extends StatelessWidget {
  const SignedInScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [SignOutButton()]),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A centred icon + heading + message, used by screens that are filled in
/// by later milestones.
class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.icon,
    required this.heading,
    required this.message,
  });

  final IconData icon;
  final String heading;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              heading,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
