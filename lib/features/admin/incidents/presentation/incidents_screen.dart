import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import 'incident_panel.dart';
import 'widgets/incident_filters.dart';
import 'widgets/incident_table.dart';

/// Every recent incident in a filterable table. A row opens the incident
/// panel with all the response actions.
class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(filteredIncidentsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Incidents', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('The 300 most recent incidents, newest first.'),
          const SizedBox(height: 12),
          const IncidentFilters(),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: incidents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Could not load incidents.')),
                data: (list) => list.isEmpty
                    ? const Center(child: Text('No incidents match.'))
                    : IncidentTable(
                        incidents: list,
                        onOpen: (i) => showIncidentPanel(context, i.id),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
