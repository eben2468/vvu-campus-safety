import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../incidents/presentation/incident_panel.dart';
import '../../../providers.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_views.dart';

/// The latest timeline entries from every incident, newest first.
class ActivityFeed extends ConsumerWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    final textTheme = Theme.of(context).textTheme;
    return activity.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState.error('activity'),
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.bolt_outlined,
              title: 'No activity yet',
              message: 'Updates on incidents will appear here.',
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final event = item.event;
                final (icon, color) = _styleFor(event.type);
                return ListTile(
                  dense: true,
                  leading: IconBadge(icon: icon, color: color, size: 32),
                  title: Text(
                    event.text.isEmpty ? event.type.value : event.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: event.timestamp == null
                      ? null
                      : Text(
                          timeAgo(event.timestamp!),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                  onTap: () => showIncidentPanel(context, item.incidentId),
                );
              },
            ),
    );
  }

  static (IconData, Color) _styleFor(IncidentEventType type) => switch (type) {
    IncidentEventType.created => (Icons.add_alert, AppColors.sosRed),
    IncidentEventType.alerted => (Icons.notifications_active, AppColors.sosRed),
    IncidentEventType.accepted => (Icons.check, AppColors.inProgress),
    IncidentEventType.assigned => (Icons.group_add, AppColors.vvuBlue),
    IncidentEventType.onScene => (Icons.place, AppColors.inProgress),
    IncidentEventType.note => (Icons.notes, AppColors.vvuBlue),
    IncidentEventType.resolved => (Icons.task_alt, AppColors.safeGreen),
    IncidentEventType.falseAlarm => (Icons.do_not_disturb, AppColors.muted),
    IncidentEventType.cancelled => (Icons.verified_user, AppColors.muted),
  };
}
