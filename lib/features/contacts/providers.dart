// Riverpod providers for the emergency contacts feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/emergency_contact.dart';
import '../../services/firestore_service.dart';
import '../auth/providers.dart';
import 'data/contacts_repository.dart';

final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepository(ref.watch(firestoreProvider));
});

/// The signed-in user's emergency contacts.
final contactsProvider = StreamProvider<List<EmergencyContact>>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.profile?.uid));
  if (uid == null) return Stream.value(const []);
  return ref.watch(contactsRepositoryProvider).watch(uid);
});
