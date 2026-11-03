import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/admin_repository.dart';
import '../../providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_views.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: kPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'Audit log',
            subtitle:
                'Every account, role, roster and settings change made '
                'from the dashboard. Entries can\'t be edited or deleted.',
          ),
          Expanded(
            child: SectionCard(
              title: 'Recent actions',
              subtitle: 'The 200 most recent, newest first',
              icon: Icons.history,
              expand: true,
              padding: EdgeInsets.zero,
              child: logs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const EmptyState.error('the audit log'),
                data: (entries) => entries.isEmpty
                    ? const EmptyState(
                        icon: Icons.history,
                        title: 'No admin actions yet',
                        message:
                            'Changes made from the dashboard will be '
                            'recorded here.',
                      )
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final entry = entries[i];
                          final (icon, color) = _styleFor(entry.action);
                          return ListTile(
                            leading: IconBadge(icon: icon, color: color),
                            title: Text(entry.describe(nameOf)),
                            subtitle: Text(
                              'By ${nameOf(entry.actorId)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            trailing: entry.timestamp == null
                                ? null
                                : Text(
                                    formatDateTime(entry.timestamp!),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.muted,
                                    ),
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

  static (IconData, Color) _styleFor(String action) => switch (action) {
    'user_created' => (Icons.person_add_alt_1, AppColors.safeGreen),
    'role_changed' => (Icons.manage_accounts, AppColors.vvuBlue),
    'user_deactivated' => (Icons.block, AppColors.sosRed),
    'user_reactivated' => (Icons.restart_alt, AppColors.safeGreen),
    'roster_imported' => (Icons.badge_outlined, AppColors.vvuBlue),
    'settings_updated' => (Icons.tune, AppColors.inProgress),
    _ => (Icons.history, AppColors.muted),
  };
}

final _everyoneProvider = StreamProvider((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers(UserGroup.all);
});
