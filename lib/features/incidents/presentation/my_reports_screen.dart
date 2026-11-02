import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../routing/routes.dart';
import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../providers.dart';
import 'widgets/status_chip.dart';

/// The user's own SOS alerts and reports, newest first, with their status.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(myIncidentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My reports')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.report),
        icon: const Icon(Icons.add),
        label: const Text('New report'),
      ),
      body: incidents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load your reports.')),
        data: (list) => list.isEmpty
            ? const InfoPanel(
                icon: Icons.inbox_outlined,
                heading: 'No reports yet',
                message: 'Incidents you report or SOS alerts you send will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final incident = list[i];
                  final createdAt = incident.createdAt;
                  return ListTile(
                    leading: Icon(incident.isSos ? Icons.sos : Icons.report),
                    title: Text(
                      incident.isSos ? 'SOS alert' : incident.category,
                    ),
                    subtitle: Text(
                      [
                        if (createdAt != null) formatDateTime(createdAt),
                        if (incident.pendingSync) 'Waiting to send',
                      ].join(' · '),
                    ),
                    trailing: StatusChip(incident.status),
                    onTap: () => context.push(Routes.reportDetail(incident.id)),
                  );
                },
              ),
      ),
    );
  }
}
