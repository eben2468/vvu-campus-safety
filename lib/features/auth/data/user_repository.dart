import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../models/app_user.dart';

/// Reads `users/{uid}` profiles.
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Live profile, or null if the document doesn't exist yet.
  Stream<AppUser?> watchUser(String uid) {
    return _firestore
        .collection(Collections.users)
        .doc(uid)
        .snapshots()
        .map(
          (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
        );
  }
}
