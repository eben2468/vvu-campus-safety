import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../providers.dart';

/// Reminds a signed-in user to confirm their email address. Users with an
/// unconfirmed email can still use the app (docs/PRD.md §4.1).
class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.emailVerified) return const SizedBox.shrink();

    final email = session.profile?.email;
    final repository = ref.read(authRepositoryProvider);

    Future<void> run(Future<void> Function() action, String done) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
        messenger.showSnackBar(SnackBar(content: Text(done)));
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    }

    return MaterialBanner(
      leading: const Icon(Icons.mark_email_unread_outlined),
      content: Text(
        email == null || email.isEmpty
            ? 'Please confirm your email address using the link we sent you.'
            : 'Please confirm your email address using the link we sent to $email.',
      ),
      actions: [
        TextButton(
          onPressed: () => run(
            repository.resendVerificationEmail,
            'Confirmation email sent.',
          ),
          child: const Text('Resend'),
        ),
        TextButton(
          onPressed: () =>
              run(repository.refreshUser, 'Checked your email status.'),
          child: const Text("I've confirmed"),
        ),
      ],
    );
  }
}
