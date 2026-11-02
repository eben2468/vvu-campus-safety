import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/incident.dart';
import '../../models/incident_event.dart';
import '../../services/firestore_service.dart';
import 'data/incident_repository.dart';

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  return IncidentRepository(ref.watch(firestoreProvider));
});

/// One incident, live.
final incidentProvider = StreamProvider.family<Incident?, String>((ref, id) {
  return ref.watch(incidentRepositoryProvider).watchIncident(id);
});

/// An incident's timeline, oldest first.
final incidentEventsProvider =
    StreamProvider.family<List<IncidentEvent>, String>((ref, id) {
      return ref.watch(incidentRepositoryProvider).watchEvents(id);
    });
