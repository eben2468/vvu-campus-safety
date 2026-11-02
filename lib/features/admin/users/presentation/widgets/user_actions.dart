import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/errors/app_exception.dart';
import '../../../../../models/app_user.dart';
import '../../../providers.dart';

/// The "⋮" menu on a user row: change role, deactivate or reactivate.
/// Both go through `adminSetRole`.
class UserActions extends ConsumerWidget {
  const UserActions({super.key, required this.user});

  final AppUser user;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepositoryProvider);
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (choice) async {
        if (choice == 'role') {
          final role = await _pickRole(context, user);
          if (role == null || !context.mounted) return;
          await _run(
            context,
            () => repo.setRole(user.uid, role),
            '${user.fullName} is now ${_roleLabel(role).toLowerCase()}.',
          );
        } else {
          final deactivate = !user.deactivated;
          if (deactivate && !await _confirmDeactivate(context, user)) return;
          if (!context.mounted) return;
          await _run(
            context,
            () => repo.setDeactivated(user.uid, deactivated: deactivate),
            deactivate
                ? '${user.fullName} was deactivated and signed out.'
                : '${user.fullName} can sign in again.',
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'role', child: Text('Change role…')),
        PopupMenuItem(
          value: 'active',
          child: Text(user.deactivated ? 'Reactivate' : 'Deactivate…'),
        ),
      ],
    );
  }
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.student => 'Student',
  UserRole.staff => 'Staff',
  UserRole.officer => 'Officer',
  UserRole.admin => 'Admin',
};

Future<UserRole?> _pickRole(BuildContext context, AppUser user) {
  var selected = user.role ?? UserRole.student;
  return showDialog<UserRole>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Role for ${user.fullName}'),
        content: RadioGroup<UserRole>(
          groupValue: selected,
          onChanged: (role) => setState(() => selected = role!),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in UserRole.values)
                RadioListTile<UserRole>(
                  value: role,
                  title: Text(_roleLabel(role)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: selected == user.role
                ? null
                : () => Navigator.pop(context, selected),
            child: const Text('Change role'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> _confirmDeactivate(BuildContext context, AppUser user) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Deactivate ${user.fullName}?'),
      content: const Text(
        'They are signed out straight away and can no longer sign in, raise '
        'alerts or receive them. Their incidents stay on record. You can '
        'reactivate them later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Shown in the table's role column.
String roleLabel(UserRole? role) => role == null ? '—' : _roleLabel(role);
