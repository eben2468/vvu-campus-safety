import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/launchers.dart';
import '../../../models/incident.dart';
import '../../../models/incident_status.dart';
import '../../auth/providers.dart';
import '../../incidents/presentation/widgets/event_timeline.dart';
import '../../incidents/presentation/widgets/incident_map.dart';
import '../../incidents/presentation/widgets/status_chip.dart';
import '../../incidents/providers.dart';

/// Officer view of one alert: live map of the reporter, call, navigate,
/// accept. More actions (on scene, resolve, notes) arrive in Milestone 4.
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

class _AlertDetail extends ConsumerStatefulWidget {
  const _AlertDetail({required this.incident});

  final Incident incident;

  @override
  ConsumerState<_AlertDetail> createState() => _AlertDetailState();
}

class _AlertDetailState extends ConsumerState<_AlertDetail> {
  bool _accepting = false;

  Future<void> _accept() async {
    final officer = ref.read(sessionProvider).profile;
    if (officer == null) return;
    setState(() => _accepting = true);
    try {
      await ref
          .read(incidentRepositoryProvider)
          .accept(widget.incident.id, officer);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
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
              if (incident.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(incident.description),
              ],
              const SizedBox(height: 16),
              if (incident.status == IncidentStatus.alerted)
                FilledButton.icon(
                  onPressed: _accepting ? null : _accept,
                  icon: const Icon(Icons.check),
                  label: const Text('Accept'),
                ),
              if (incident.assignedTo.contains(myUid))
                const Text(
                  'You accepted this alert.',
                  textAlign: TextAlign.center,
                ),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: point == null
                          ? null
                          : () =>
                                openDirections(point.latitude, point.longitude),
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigate'),
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
