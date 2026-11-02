import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/formatters.dart';
import '../providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/id_details_fields.dart';

/// Shown when someone is signed in but their account isn't linked to a VVU
/// ID yet — e.g. registration was interrupted before the ID check finished.
class VerifyIdScreen extends ConsumerStatefulWidget {
  const VerifyIdScreen({super.key});

  @override
  ConsumerState<VerifyIdScreen> createState() => _VerifyIdScreenState();
}

class _VerifyIdScreenState extends ConsumerState<VerifyIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = IdDetailsControllers();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyId(
            fullName: _id.fullName.text.trim(),
            idNumber: normalizeIdNumber(_id.idNumber.text),
            phone: normalizeGhanaPhone(_id.phone.text)!,
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
      title: 'Verify your VVU ID',
      subtitle:
          'Your account is not linked to a VVU ID yet. '
          'Enter your details to finish setting it up.',
      children: [
        if (_error != null) FormMessage(_error!),
        Form(
          key: _formKey,
          child: IdDetailsFields(controllers: _id),
        ),
        const SizedBox(height: 24),
        SubmitButton(label: 'Verify ID', busy: _busy, onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () => ref.read(authRepositoryProvider).signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
