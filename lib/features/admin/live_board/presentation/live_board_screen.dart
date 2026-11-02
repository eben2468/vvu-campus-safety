import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/signed_in_scaffold.dart';

/// Admin dashboard landing page (web). The live map, incident list and
/// summary cards are added in Milestone 5.
class LiveBoardScreen extends StatelessWidget {
  const LiveBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignedInScaffold(
      title: 'Security dashboard',
      body: InfoPanel(
        icon: Icons.dashboard,
        heading: 'Live board',
        message: 'Active incidents on the campus map will appear here.',
      ),
    );
  }
}
