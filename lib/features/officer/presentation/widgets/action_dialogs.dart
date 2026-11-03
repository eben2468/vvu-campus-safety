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
  return showDialog<String>(
    context: context,
    builder: (_) => _NoteDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      required: required,
    ),
  );
}

/// Owns its text controller so it is disposed only after the closing
/// animation, not as soon as the dialog's future completes.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.required,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final bool required;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: widget.hint),
          validator: (value) => widget.required && (value ?? '').trim().isEmpty
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
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
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
