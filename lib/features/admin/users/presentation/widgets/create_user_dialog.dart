import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../providers.dart';

/// Form for a new officer or admin account (`adminCreateUser`). The person
/// signs in with the temporary password and can change it with
/// "Forgot password".
class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.officer;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .createUser(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
            phone: normalizeGhanaPhone(_phone.text)!,
            role: _role,
          );
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add officer or admin'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) FormMessage(_error!),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: Validators.fullName,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '024 123 4567',
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.ghanaPhone,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  helperText: 'Give this to the person; they can change it.',
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 16),
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.officer,
                    label: Text('Officer'),
                  ),
                  ButtonSegment(value: UserRole.admin, label: Text('Admin')),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.single),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Creating…' : 'Create account'),
        ),
      ],
    );
  }
}
