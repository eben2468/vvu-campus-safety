import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/emergency_contact.dart';

/// What the contact form returns.
typedef ContactDetails = ({String name, String phone, String relationship});

/// Add or edit a contact. Returns null if cancelled.
Future<ContactDetails?> showContactDialog(
  BuildContext context, {
  EmergencyContact? existing,
}) {
  return showDialog<ContactDetails>(
    context: context,
    builder: (_) => _ContactDialog(existing: existing),
  );
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({this.existing});

  final EmergencyContact? existing;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _relationship = TextEditingController(
    text: widget.existing?.relationship,
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop<ContactDetails>(context, (
      name: _name.text.trim(),
      phone: normalizeGhanaPhone(_phone.text)!,
      relationship: _relationship.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add contact' : 'Edit contact'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: Validators.fullName,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: '024 123 4567',
              ),
              validator: Validators.ghanaPhone,
            ),
            TextFormField(
              controller: _relationship,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Relationship (optional)',
                hintText: 'e.g. Mother, Room mate',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
