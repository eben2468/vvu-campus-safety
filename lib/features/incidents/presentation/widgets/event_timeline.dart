import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../models/incident_event.dart';

/// An incident's `events`, oldest first.
class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key, required this.events});

  final List<IncidentEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No updates yet.'),
      );
    }
    return Column(
      children: [
        for (final event in events)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, size: 12),
            title: Text(event.text.isEmpty ? event.type.value : event.text),
            trailing: event.timestamp == null
                ? null
                : Text(formatTime(event.timestamp!)),
          ),
      ],
    );
  }
}
