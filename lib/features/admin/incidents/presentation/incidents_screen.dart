import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';
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
    final count = incidents.value?.length;
    return Padding(
      padding: kPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Incidents',
            subtitle: count == null
                ? 'The 300 most recent incidents, newest first.'
                : 'Showing $count of the 300 most recent incidents, newest '
                      'first. Click a row to open it.',
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: IncidentFilters(),
            ),
          ),
          const SizedBox(height: kGap),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: incidents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const EmptyState.error('incidents'),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No incidents match',
                        message: 'Try another status, type or search.',
                      )
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
