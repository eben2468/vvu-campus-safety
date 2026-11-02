import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../../auth/providers.dart';

/// Officer home (also used by admins on mobile). The on-duty toggle and
/// alert queue are added in Milestone 2.
class OfficerHomeScreen extends ConsumerWidget {
  const OfficerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider).profile?.firstName;
    return SignedInScaffold(
      title: 'Security officer',
      body: InfoPanel(
        icon: Icons.local_police,
        heading: name == null ? 'Officer home' : 'Hello, $name',
        message: 'Incoming SOS alerts and reports will appear here.',
      ),
    );
  }
}
