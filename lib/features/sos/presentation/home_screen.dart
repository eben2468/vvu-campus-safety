import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../../auth/providers.dart';

/// Student and staff home. The SOS button is added in Milestone 2.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final name = session.profile?.firstName;
    return SignedInScaffold(
      title: 'VVU Campus Safety',
      body: InfoPanel(
        icon: Icons.verified_user,
        heading: name == null ? 'Welcome' : 'Welcome, $name',
        message:
            'Your VVU ID is verified as ${session.role?.name ?? 'a member'}. '
            'Emergency SOS and incident reporting will appear here.',
      ),
    );
  }
}
