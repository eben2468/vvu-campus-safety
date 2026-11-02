import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import 'widgets/incident_card.dart';

/// Officer home (also admins on mobile): on-duty switch and the live queue
/// of open incidents.
class OfficerHomeScreen extends ConsumerWidget {
  const OfficerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(sessionProvider).profile;
    final queue = ref.watch(activeIncidentsProvider);
    final onDuty = profile?.onDuty ?? false;

    return SignedInScaffold(
      title: 'Security officer',
      showAnnouncements: true,
      body: Column(
        children: [
          SwitchListTile(
            value: onDuty,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(userRepositoryProvider)
                      .setOnDuty(profile.uid, onDuty: value),
            title: Text(onDuty ? 'On duty' : 'Off duty'),
            subtitle: Text(
              onDuty
                  ? 'You get a push for every new SOS and report.'
                  : 'Turn on to receive SOS alerts on this phone.',
            ),
            secondary: Icon(onDuty ? Icons.shield : Icons.shield_outlined),
          ),
          const Divider(height: 1),
          Expanded(
            child: queue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Text('Could not load alerts. Check your connection.'),
              ),
              data: (incidents) => incidents.isEmpty
                  ? const InfoPanel(
                      icon: Icons.check_circle_outline,
                      heading: 'All clear',
                      message: 'There are no open alerts right now.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: incidents.length,
                      itemBuilder: (context, i) => IncidentCard(
                        incident: incidents[i],
                        onTap: () =>
                            context.push(Routes.incidentAlert(incidents[i].id)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
