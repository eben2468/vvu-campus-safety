import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../auth/presentation/widgets/email_verification_banner.dart';
import '../../auth/presentation/widgets/sign_out_button.dart';
import '../../auth/providers.dart';
import 'new_sos_banner.dart';

/// One entry in the dashboard's side navigation.
typedef _Destination = ({String route, String label, IconData icon});

const List<_Destination> _destinations = [
  (route: Routes.dashboard, label: 'Live board', icon: Icons.dashboard),
  (route: Routes.dashboardIncidents, label: 'Incidents', icon: Icons.list_alt),
  (route: Routes.dashboardUsers, label: 'Users', icon: Icons.people),
  (route: Routes.dashboardRoster, label: 'ID roster', icon: Icons.badge),
  (
    route: Routes.dashboardAnnouncements,
    label: 'Announcements',
    icon: Icons.campaign,
  ),
];

/// Frame for every admin dashboard page: app bar, side navigation and the
/// new-SOS banner, which shows on whichever page is open.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  /// The current path, to highlight the matching destination.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(sessionProvider.select((s) => s.profile?.fullName));
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    // The live board is '/dashboard', a prefix of every other page.
    final selected = _destinations.lastIndexWhere(
      (d) => location.startsWith(d.route),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('VVU Campus Safety — Security dashboard'),
        actions: [
          if (name != null && wide)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(name),
              ),
            ),
          const SignOutButton(),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: wide,
            labelType: wide ? null : NavigationRailLabelType.all,
            selectedIndex: selected < 0 ? 0 : selected,
            onDestinationSelected: (i) => context.go(_destinations[i].route),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const EmailVerificationBanner(),
                const NewSosBanner(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
