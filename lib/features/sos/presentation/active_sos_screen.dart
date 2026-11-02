import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme.dart';
import '../../../models/incident.dart';
import '../../../models/incident_status.dart';
import '../../../services/location_service.dart';
import '../../auth/providers.dart';
import '../../incidents/providers.dart';
import '../data/sos_location_tracker.dart';
import 'widgets/call_security_button.dart';
import 'widgets/hold_to_confirm_button.dart';
import 'widgets/offline_fallback_card.dart';

/// Shown to the reporter while their SOS is open. Streams their location
/// for as long as this screen is up (the SOS is active).
class ActiveSosScreen extends ConsumerStatefulWidget {
  const ActiveSosScreen({super.key, required this.incident});

  final Incident incident;

  @override
  ConsumerState<ActiveSosScreen> createState() => _ActiveSosScreenState();
}

class _ActiveSosScreenState extends ConsumerState<ActiveSosScreen> {
  late final SosLocationTracker _tracker = SosLocationTracker(
    incidentId: widget.incident.id,
    location: ref.read(locationServiceProvider),
    incidents: ref.read(incidentRepositoryProvider),
  );

  @override
  void initState() {
    super.initState();
    _tracker.start();
  }

  @override
  void dispose() {
    // Leaving this screen means the SOS closed: stop sharing location.
    _tracker.stop();
    super.dispose();
  }

  Future<void> _imSafe() async {
    final reporter = ref.read(sessionProvider).profile;
    if (reporter == null) return;
    try {
      await ref
          .read(incidentRepositoryProvider)
          .cancelSos(widget.incident, reporter);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final events =
        ref.watch(incidentEventsProvider(incident.id)).value ?? const [];
    final acceptedBy = events
        .where((e) => e.type == IncidentEventType.accepted)
        .lastOrNull
        ?.actorName;
    final canCancel = incident.status.canTransition(
      IncidentStatus.resolved,
      by: StatusActor.reporter,
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS active'),
        backgroundColor: AppColors.sosRed,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              _statusIcon(incident.status),
              size: 72,
              color: AppColors.sosRed,
            ),
            const SizedBox(height: 12),
            Text(
              _headline(incident, acceptedBy),
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              incident.currentLocation == null
                  ? 'We could not get your location yet. If you can, tell security where you are.'
                  : 'Your location is being shared with security until this alert is closed.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (incident.pendingSync) ...[
              OfflineFallbackCard(incident: incident),
              const SizedBox(height: 16),
            ],
            const CallSecurityButton(filled: true),
            const SizedBox(height: 32),
            if (canCancel)
              HoldToConfirmButton(
                label: "Hold if you're safe",
                onConfirmed: _imSafe,
              )
            else
              Text(
                'An officer is responding. If you are safe now, tell them by phone.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  static String _headline(Incident incident, String? officer) {
    if (incident.pendingSync && incident.status == IncidentStatus.newIncident) {
      return 'Sending your alert…';
    }
    return switch (incident.status) {
      IncidentStatus.newIncident => 'Alert sent',
      IncidentStatus.alerted => 'Security has been alerted',
      IncidentStatus.accepted => '${officer ?? 'An officer'} is on the way',
      IncidentStatus.onScene => '${officer ?? 'An officer'} has arrived',
      _ => 'Alert closed',
    };
  }

  static IconData _statusIcon(IncidentStatus status) => switch (status) {
    IncidentStatus.accepted => Icons.directions_run,
    IncidentStatus.onScene => Icons.local_police,
    _ => Icons.campaign,
  };
}
