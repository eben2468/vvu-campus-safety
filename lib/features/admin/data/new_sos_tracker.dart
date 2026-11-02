import '../../../models/incident.dart';
import '../../../models/incident_status.dart';

/// Spots SOS alerts that arrive while the dashboard is open, so it can
/// sound and flash (PRD §4.8).
///
/// The first list it sees is the starting point: alerts that were already
/// open when the page loaded are shown in the list but don't sound.
class NewSosTracker {
  Set<String>? _seen;

  /// Returns the SOS incidents in [active] that weren't there last time and
  /// are still waiting for an officer.
  List<Incident> update(List<Incident> active) {
    final sos = active.where((i) => i.isSos).toList();
    final seen = _seen;
    _seen = {for (final i in sos) i.id};
    if (seen == null) return const [];
    return [
      for (final i in sos)
        if (!seen.contains(i.id) && isWaiting(i)) i,
    ];
  }

  /// Not yet accepted by anyone.
  static bool isWaiting(Incident incident) =>
      incident.status == IncidentStatus.newIncident ||
      incident.status == IncidentStatus.alerted;
}
