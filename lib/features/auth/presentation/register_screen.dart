import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../routing/routes.dart';
import '../providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/id_details_fields.dart';
import 'widgets/password_field.dart';

/// Self sign-up for students and staff. The VVU ID is checked against the
/// university roster by the `verifyId` Cloud Function.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = IdDetailsControllers();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the router moves to the home screen.
      await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _id.fullName.text.trim(),
            idNumber: normalizeIdNumber(_id.idNumber.text),
            email: _email.text,
            phone: normalizeGhanaPhone(_id.phone.text)!,
            password: _password.text,
          );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'For VVU students and staff. Your ID is checked against university records.',
      children: [
        if (_error != null) FormMessage(_error!),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                IdDetailsFields(controllers: _id),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  validator: Validators.password,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  validator: Validators.confirmPassword(() => _password.text),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SubmitButton(label: 'Create account', busy: _busy, onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => context.go(Routes.login),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
