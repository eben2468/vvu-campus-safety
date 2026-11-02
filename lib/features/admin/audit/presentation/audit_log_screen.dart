import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../data/admin_repository.dart';
import '../../providers.dart';

/// Read-only list of admin actions (PRD §4.12), newest first. Entries are
/// written only by the admin Cloud Functions.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogsProvider);
    // Names for actor and target uids; everyone is loaded, so the list
    // also names students whose role changed.
    final users = ref.watch(_everyoneProvider).value ?? const [];
    final names = {for (final u in users) u.uid: u.fullName};
    String nameOf(String uid) => names[uid] ?? uid;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Audit log', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'Every account, role, roster and settings change made from the '
            'dashboard. The 200 most recent are shown.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: logs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Could not load the audit log.')),
                data: (entries) => entries.isEmpty
                    ? const Center(child: Text('No admin actions yet.'))
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final entry = entries[i];
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(entry.describe(nameOf)),
                            subtitle: Text(
                              [
                                'By ${nameOf(entry.actorId)}',
                                if (entry.timestamp != null)
                                  formatDateTime(entry.timestamp!),
                              ].join(' · '),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _everyoneProvider = StreamProvider((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers(UserGroup.all);
});
