import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../services/firestore_service.dart';
import '../incidents/providers.dart';
import 'data/officer_repository.dart';

/// Open incidents for the officer queue: SOS first, then oldest first.
final activeIncidentsProvider = StreamProvider<List<Incident>>((ref) {
  return ref.watch(incidentRepositoryProvider).watchActiveIncidents();
});

final officerRepositoryProvider = Provider<OfficerRepository>((ref) {
  return OfficerRepository(ref.watch(firestoreProvider));
});

/// Officers and admins who can be assigned, on-duty first.
final securityTeamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(officerRepositoryProvider).watchSecurityTeam();
});
