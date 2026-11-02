import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/launchers.dart';
import '../../../../../models/incident.dart';
import '../../../../incidents/presentation/widgets/event_timeline.dart';
import '../../../../incidents/presentation/widgets/incident_map.dart';
import '../../../../incidents/presentation/widgets/photo_gallery.dart';
import '../../../../incidents/providers.dart';
import '../../../../officer/presentation/widgets/officer_actions.dart';
import '../../../../officer/providers.dart';

/// The Details tab of the dashboard's incident panel: map, facts, photos,
/// the officer actions (admins can do all of them) and the timeline.
class IncidentDetails extends ConsumerWidget {
  const IncidentDetails({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(incidentEventsProvider(incident.id)).value ?? const [];
    final team = ref.watch(securityTeamProvider).value ?? const [];
    final names = {for (final user in team) user.uid: user.fullName};
    final textTheme = Theme.of(context).textTheme;
    final point = incident.currentLocation;

    final facts = <(String, String)>[
      ('Reporter', incident.reporterName),
      if (incident.reporterPhone.isNotEmpty) ('Phone', incident.reporterPhone),
      if (incident.locationLabel != null) ('Near', incident.locationLabel!),
      if (incident.createdAt != null)
        ('Raised', formatDateTime(incident.createdAt!)),
      if (incident.responseSeconds != null)
        (
          'Response time',
          formatDuration(Duration(seconds: incident.responseSeconds!)),
        ),
      if (incident.resolvedAt != null)
        ('Closed', formatDateTime(incident.resolvedAt!)),
      (
        'Assigned',
        incident.assignedTo.isEmpty
            ? 'Nobody yet'
            : incident.assignedTo
                  .map((uid) => names[uid] ?? 'Officer')
                  .join(', '),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 220,
          child: IncidentMap(point: point, label: incident.reporterName),
        ),
        const SizedBox(height: 16),
        for (final (label, value) in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(label, style: textTheme.labelLarge),
                ),
                Expanded(child: SelectableText(value)),
              ],
            ),
          ),
        if (incident.cancelledByReporter)
          const Text('The reporter marked themselves safe.'),
        if (incident.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(incident.description),
        ],
        if (incident.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          PhotoGallery(urls: incident.mediaUrls),
        ],
        const SizedBox(height: 16),
        OfficerActions(incident: incident),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            if (incident.reporterPhone.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => callNumber(incident.reporterPhone),
                icon: const Icon(Icons.call),
                label: const Text('Call reporter'),
              ),
            if (point != null)
              OutlinedButton.icon(
                onPressed: () =>
                    openDirections(point.latitude, point.longitude),
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Timeline', style: textTheme.titleMedium),
        EventTimeline(events: events),
      ],
    );
  }
}
