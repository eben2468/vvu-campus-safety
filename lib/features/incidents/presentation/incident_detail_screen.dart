import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/incident.dart';
import '../../../routing/routes.dart';
import '../../sos/presentation/widgets/call_security_button.dart';
import '../providers.dart';
import 'widgets/event_timeline.dart';
import 'widgets/incident_map.dart';
import 'widgets/photo_gallery.dart';
import 'widgets/status_chip.dart';

/// The reporter's view of one of their incidents: details, photos, map
/// pin and the status timeline.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Incident')),
      body: incident.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load this incident.')),
        data: (incident) => incident == null
            ? const Center(child: Text('This incident could not be found.'))
            : _Details(incident: incident),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(incidentEventsProvider(incident.id)).value ?? const [];
    final textTheme = Theme.of(context).textTheme;
    final createdAt = incident.createdAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                incident.isSos ? 'SOS alert' : incident.category,
                style: textTheme.headlineSmall,
              ),
            ),
            StatusChip(incident.status),
          ],
        ),
        if (createdAt != null) Text('Sent ${formatDateTime(createdAt)}'),
        if (incident.pendingSync)
          const Text('Waiting for a connection to send.'),
        if (incident.cancelledByReporter)
          const Text('You marked yourself safe.'),
        if (incident.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(incident.description, style: textTheme.bodyLarge),
        ],
        if (incident.mediaUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          PhotoGallery(urls: incident.mediaUrls),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push(Routes.chat(incident.id)),
          icon: const Icon(Icons.chat),
          label: const Text('Chat with security'),
        ),
        const SizedBox(height: 8),
        const CallSecurityButton(),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: IncidentMap(
              point: incident.location,
              label: incident.locationLabel ?? 'Incident',
              emptyMessage: 'No location was attached.',
            ),
          ),
        ),
        if (incident.locationLabel != null)
          Text('Near ${incident.locationLabel}'),
        const SizedBox(height: 24),
        Text('Updates', style: textTheme.titleMedium),
        EventTimeline(events: events),
      ],
    );
  }
}
