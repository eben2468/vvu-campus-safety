import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../models/app_user.dart';
import '../../../auth/providers.dart';
import '../../data/admin_repository.dart';
import '../../providers.dart';
import 'widgets/create_user_dialog.dart';
import 'widgets/user_actions.dart';

/// Users page (PRD §4.11): list and search users, add officers and admins,
/// change roles and deactivate accounts.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';

  bool _matches(AppUser user) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      user.fullName,
      user.email,
      user.phone,
      user.idNumber ?? '',
    ].any((text) => text.toLowerCase().contains(query));
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateUserDialog(),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(userGroupProvider);
    final users = ref.watch(usersProvider);
    final myUid = ref.watch(sessionProvider.select((s) => s.profile?.uid));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Users',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.person_add),
                label: const Text('Add officer or admin'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SegmentedButton<UserGroup>(
                segments: [
                  for (final g in UserGroup.values)
                    ButtonSegment(value: g, label: Text(g.label)),
                ],
                selected: {group},
                onSelectionChanged: (s) =>
                    ref.read(userGroupProvider.notifier).set(s.single),
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search name, email, phone or ID',
                    isDense: true,
                  ),
                  onChanged: (text) => setState(() => _search = text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: users.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Could not load users.')),
                data: (list) {
                  final shown = list.where(_matches).toList();
                  if (shown.isEmpty) {
                    return const Center(child: Text('No users match.'));
                  }
                  return _UserTable(users: shown, myUid: myUid);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({required this.users, required this.myUid});

  final List<AppUser> users;
  final String? myUid;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('VVU ID')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('')),
          ],
          rows: [
            for (final user in users)
              DataRow(
                cells: [
                  DataCell(Text(user.fullName)),
                  DataCell(Text(user.email)),
                  DataCell(Text(user.phone)),
                  DataCell(Text(roleLabel(user.role))),
                  DataCell(Text(user.idNumber ?? '—')),
                  DataCell(_status(user)),
                  DataCell(
                    // Admins can't change their own account (adminSetRole).
                    user.uid == myUid
                        ? const Text('You')
                        : UserActions(user: user),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _status(AppUser user) {
    if (user.deactivated) {
      return const Text(
        'Deactivated',
        style: TextStyle(color: AppColors.sosRed),
      );
    }
    if (user.onDuty) {
      return const Text(
        'On duty',
        style: TextStyle(color: AppColors.safeGreen),
      );
    }
    return Text(
      user.falseAlarmCount > 0
          ? 'Active · ${user.falseAlarmCount} false alarm(s)'
          : 'Active',
    );
  }
}
