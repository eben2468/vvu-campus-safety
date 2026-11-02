import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/incident.dart';
import '../incidents/providers.dart';

/// Open incidents for the officer queue: SOS first, then oldest first.
final activeIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  return ref.watch(incidentRepositoryProvider).watchActiveIncidents();
});
