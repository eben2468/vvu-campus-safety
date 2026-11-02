import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../incidents/presentation/incident_panel.dart';
import '../../../providers.dart';

/// The latest timeline entries from every incident, newest first.
class ActivityFeed extends ConsumerWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    return activity.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load activity.')),
      data: (items) => items.isEmpty
          ? const Center(child: Text('No activity yet.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final event = item.event;
                return ListTile(
                  dense: true,
                  leading: Icon(_iconFor(event.type)),
                  title: Text(
                    event.text.isEmpty ? event.type.value : event.text,
                  ),
                  subtitle: event.timestamp == null
                      ? null
                      : Text(timeAgo(event.timestamp!)),
                  onTap: () => showIncidentPanel(context, item.incidentId),
                );
              },
            ),
    );
  }

  static IconData _iconFor(IncidentEventType type) => switch (type) {
    IncidentEventType.created => Icons.add_alert,
    IncidentEventType.alerted => Icons.notifications_active,
    IncidentEventType.accepted => Icons.check,
    IncidentEventType.assigned => Icons.group_add,
    IncidentEventType.onScene => Icons.place,
    IncidentEventType.note => Icons.notes,
    IncidentEventType.resolved => Icons.task_alt,
    IncidentEventType.falseAlarm => Icons.do_not_disturb,
    IncidentEventType.cancelled => Icons.verified_user,
  };
}
