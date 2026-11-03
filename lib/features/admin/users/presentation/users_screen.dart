import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_user.dart';
import '../../../auth/providers.dart';
import '../../data/admin_repository.dart';
import '../../providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';
import 'widgets/create_user_dialog.dart';
import 'widgets/user_table.dart';

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
      padding: kPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Users',
            subtitle:
                'Find anyone with an account, add security staff and '
                'manage roles.',
            actions: [
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add officer or admin'),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<UserGroup>(
                    showSelectedIcon: false,
                    segments: [
                      for (final g in UserGroup.values)
                        ButtonSegment(value: g, label: Text(g.label)),
                    ],
                    selected: {group},
                    onSelectionChanged: (s) =>
                        ref.read(userGroupProvider.notifier).set(s.single),
                  ),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search name, email, phone or ID',
                      ),
                      onChanged: (text) => setState(() => _search = text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: kGap),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: users.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const EmptyState.error('users'),
                data: (list) {
                  final shown = list.where(_matches).toList();
                  if (shown.isEmpty) {
                    return EmptyState(
                      icon: Icons.person_search_outlined,
                      title: list.isEmpty
                          ? 'No ${group.label.toLowerCase()} yet'
                          : 'No users match "$_search"',
                    );
                  }
                  return UserTable(users: shown, myUid: myUid);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
