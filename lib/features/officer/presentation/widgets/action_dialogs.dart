import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_user.dart';
import '../../providers.dart';

/// Asks for a note. Returns the text ('' if optional and left blank), or
/// null if the officer cancelled.
Future<String?> askForNote(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  bool required = false,
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint),
          validator: (value) => required && (value ?? '').trim().isEmpty
              ? 'Write a note first.'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

/// Lets an officer pick a colleague to add to the incident.
Future<AppUser?> pickOfficer(
  BuildContext context, {
  required List<String> exclude,
}) {
  return showModalBottomSheet<AppUser>(
    context: context,
    showDragHandle: true,
    builder: (_) => _OfficerPicker(exclude: exclude),
  );
}

class _OfficerPicker extends ConsumerWidget {
  const _OfficerPicker({required this.exclude});

  final List<String> exclude;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(securityTeamProvider);
    return SafeArea(
      child: team.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Could not load the security team.'),
        ),
        data: (officers) {
          final choices = officers
              .where((o) => !exclude.contains(o.uid))
              .toList();
          if (choices.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Everyone on the team is already assigned.'),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final officer in choices)
                ListTile(
                  leading: Icon(
                    officer.onDuty ? Icons.shield : Icons.shield_outlined,
                  ),
                  title: Text(officer.fullName),
                  subtitle: Text(officer.onDuty ? 'On duty' : 'Off duty'),
                  onTap: () => Navigator.pop(context, officer),
                ),
            ],
          );
        },
      ),
    );
  }
}
