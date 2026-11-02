import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/emergency_contact.dart';
import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import 'widgets/contact_dialog.dart';

/// Up to five people who get a text with your location when you press SOS
/// (PRD §4.10).
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final uid = ref.watch(sessionProvider).profile?.uid;
    final repo = ref.read(contactsRepositoryProvider);
    final count = contacts.value?.length ?? 0;

    Future<void> add() async {
      final details = await showContactDialog(context);
      if (details == null || uid == null || !context.mounted) return;
      await _run(
        context,
        () => repo.add(
          uid,
          name: details.name,
          phone: details.phone,
          relationship: details.relationship,
          existing: count,
        ),
      );
    }

    Future<void> edit(EmergencyContact contact) async {
      final details = await showContactDialog(context, existing: contact);
      if (details == null || uid == null || !context.mounted) return;
      await _run(
        context,
        () => repo.update(
          uid,
          contact.copyWith(
            name: details.name,
            phone: details.phone,
            relationship: details.relationship,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency contacts')),
      floatingActionButton: count >= maxEmergencyContacts
          ? null
          : FloatingActionButton.extended(
              onPressed: add,
              icon: const Icon(Icons.person_add),
              label: const Text('Add contact'),
            ),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load contacts.')),
        data: (list) => list.isEmpty
            ? const InfoPanel(
                icon: Icons.contact_phone_outlined,
                heading: 'No emergency contacts',
                message:
                    'Add up to $maxEmergencyContacts people. When you press '
                    'SOS they get a text with your location.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                children: [
                  Text(
                    'These people get a text with your location when you '
                    'press SOS ($count of $maxEmergencyContacts). Tap one to edit.',
                  ),
                  const SizedBox(height: 8),
                  for (final contact in list)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(contact.name),
                        subtitle: Text(
                          [
                            contact.phone,
                            if (contact.relationship.isNotEmpty)
                              contact.relationship,
                          ].join(' · '),
                        ),
                        onTap: () => edit(contact),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: uid == null
                              ? null
                              : () => _run(
                                  context,
                                  () => repo.remove(uid, contact.id),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
