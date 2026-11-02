import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/emergency_contact.dart';

/// The signed-in user's emergency contacts, `users/{uid}/contacts`.
/// `onIncidentCreated` texts them when the user presses SOS.
class ContactsRepository {
  ContactsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _contacts(String uid) => _firestore
      .collection(Collections.users)
      .doc(uid)
      .collection(Collections.contacts);

  /// Oldest first, so the order doesn't jump around after an edit.
  Stream<List<EmergencyContact>> watch(String uid) {
    return _contacts(uid)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              EmergencyContact.fromMap(doc.id, doc.data()),
          ],
        );
  }

  /// Adds a contact; [existing] is the current count, capped at
  /// [maxEmergencyContacts].
  Future<void> add(
    String uid, {
    required String name,
    required String phone,
    required String relationship,
    required int existing,
  }) async {
    if (existing >= maxEmergencyContacts) {
      throw const AppException(
        'You can have up to $maxEmergencyContacts contacts. Remove one first.',
      );
    }
    await _guard(
      () => _contacts(uid).add({
        'name': name.trim(),
        'phone': phone,
        'relationship': relationship.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<void> update(String uid, EmergencyContact contact) {
    return _guard(
      () => _contacts(uid).doc(contact.id).update({
        'name': contact.name.trim(),
        'phone': contact.phone,
        'relationship': contact.relationship.trim(),
      }),
    );
  }

  Future<void> remove(String uid, String contactId) {
    return _guard(() => _contacts(uid).doc(contactId).delete());
  }

  /// Saves go to the local cache straight away and sync when online, so
  /// only wait briefly for the server.
  Future<void> _guard(Future<void> Function() write) async {
    try {
      await write().timeout(const Duration(seconds: 6), onTimeout: () {});
    } on FirebaseException {
      throw const AppException('Could not save the contact. Please try again.');
    }
  }
}
