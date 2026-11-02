import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/launchers.dart';
import '../../../models/incident.dart';
import '../../../routing/routes.dart';
import '../../auth/providers.dart';
import '../../incidents/presentation/widgets/event_timeline.dart';
import '../../incidents/presentation/widgets/incident_map.dart';
import '../../incidents/presentation/widgets/photo_gallery.dart';
import '../../incidents/presentation/widgets/status_chip.dart';
import '../../incidents/providers.dart';
import 'widgets/officer_actions.dart';

/// Officer view of one alert: live map of the reporter, call, chat,
/// navigate, and the response actions.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    return Scaffold(
      appBar: AppBar(title: const Text('Alert')),
      body: incident.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load this alert.')),
        data: (incident) => incident == null
            ? const Center(child: Text('This alert no longer exists.'))
            : _AlertDetail(incident: incident),
      ),
    );
  }
}

class _AlertDetail extends ConsumerWidget {
  const _AlertDetail({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = incident.currentLocation;
    final events =
        ref.watch(incidentEventsProvider(incident.id)).value ?? const [];
    final myUid = ref.watch(sessionProvider).profile?.uid;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        SizedBox(
          height: 280,
          child: IncidentMap(point: point, label: incident.reporterName),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      incident.isSos ? 'SOS' : incident.category,
                      style: textTheme.headlineSmall?.copyWith(
                        color: incident.isSos ? AppColors.sosRed : null,
                      ),
                    ),
                  ),
                  StatusChip(incident.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${incident.reporterName} · ${incident.reporterPhone}',
                style: textTheme.titleMedium,
              ),
              if (incident.locationLabel != null)
                Text('Near ${incident.locationLabel}'),
              if (incident.createdAt != null)
                Text('Raised at ${formatDateTime(incident.createdAt!)}'),
              if (incident.cancelledByReporter)
                const Text('The reporter marked themselves safe.'),
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(incident.description),
              ],
              if (incident.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                PhotoGallery(urls: incident.mediaUrls),
              ],
              const SizedBox(height: 16),
              if (incident.assignedTo.contains(myUid))
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'You are assigned to this incident.',
                    textAlign: TextAlign.center,
                  ),
                ),
              OfficerActions(incident: incident),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: incident.reporterPhone.isEmpty
                          ? null
                          : () => callNumber(incident.reporterPhone),
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(Routes.chat(incident.id)),
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: point == null
                          ? null
                          : () =>
                                openDirections(point.latitude, point.longitude),
                      icon: const Icon(Icons.directions),
                      label: const Text('Go'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Timeline', style: textTheme.titleMedium),
              EventTimeline(events: events),
            ],
          ),
        ),
      ],
    );
  }
}
