import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../routing/routes.dart';
import '../providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(signOutNoticeProvider.notifier).clear();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the router moves on to the right home screen.
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(signOutNoticeProvider);
    return AuthScaffold(
      title: kIsWeb ? 'Security dashboard' : 'VVU Campus Safety',
      subtitle: 'Log in to continue',
      children: [
        if (notice != null) FormMessage(notice, isError: false),
        if (_error != null) FormMessage(_error!),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
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
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password.' : null,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(Routes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 8),
        SubmitButton(label: 'Log in', busy: _busy, onPressed: _submit),
        // Self sign-up is for students and staff, who use the mobile app.
        if (!kIsWeb) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go(Routes.register),
            child: const Text('Create an account'),
          ),
        ],
      ],
    );
  }
}
