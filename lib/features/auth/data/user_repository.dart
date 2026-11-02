import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../models/app_user.dart';

/// Reads `users/{uid}` profiles and the few fields a user may change
/// themselves (see `ownProfileUpdateAllowed` in firestore.rules).
class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection(Collections.users).doc(uid);

  /// Live profile, or null if the document doesn't exist yet.
  Stream<AppUser?> watchUser(String uid) {
    return _user(uid).snapshots().map(
      (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
    );
  }

  /// Officers only.
  Future<void> setOnDuty(String uid, {required bool onDuty}) =>
      _user(uid).update({'onDuty': onDuty});

  Future<void> addFcmToken(String uid, String token) => _user(uid).update({
    'fcmTokens': FieldValue.arrayUnion([token]),
  });

  Future<void> removeFcmToken(String uid, String token) => _user(uid).update({
    'fcmTokens': FieldValue.arrayRemove([token]),
  });
}
