import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/validators.dart';

/// Controllers for the fields `verifyId` needs.
class IdDetailsControllers {
  final fullName = TextEditingController();
  final idNumber = TextEditingController();
  final phone = TextEditingController();

  void dispose() {
    fullName.dispose();
    idNumber.dispose();
    phone.dispose();
  }
}

/// Full name, VVU ID number and phone — used by register and verify-ID.
class IdDetailsFields extends StatelessWidget {
  const IdDetailsFields({super.key, required this.controllers});

  final IdDetailsControllers controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controllers.fullName,
          decoration: const InputDecoration(
            labelText: 'Full name',
            helperText: 'As it appears on your VVU ID card',
          ),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          validator: Validators.fullName,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers.idNumber,
          decoration: const InputDecoration(
            labelText: 'VVU ID number',
            hintText: 'e.g. 223IT0100946',
          ),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 ]')),
          ],
          validator: Validators.idNumber,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controllers.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: 'e.g. 024 123 4567',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.telephoneNumber],
          validator: Validators.ghanaPhone,
        ),
      ],
    );
  }
}
