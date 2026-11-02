import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../models/app_user.dart';

/// The security team: officer and admin profiles, for assigning incidents.
class OfficerRepository {
  OfficerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Officers and admins, on-duty first, then by name.
  Stream<List<AppUser>> watchSecurityTeam() {
    return _firestore
        .collection(Collections.users)
        .where('role', whereIn: [UserRole.officer.name, UserRole.admin.name])
        .snapshots()
        .map((snap) {
          final team = [
            for (final doc in snap.docs) AppUser.fromMap(doc.id, doc.data()),
          ].where((user) => !user.deactivated).toList();
          team.sort((a, b) {
            if (a.onDuty != b.onDuty) return a.onDuty ? -1 : 1;
            return a.fullName.compareTo(b.fullName);
          });
          return team;
        });
  }
}
