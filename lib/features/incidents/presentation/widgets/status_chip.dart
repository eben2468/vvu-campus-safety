import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../models/incident_status.dart';

/// Coloured label for an incident's status.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      IncidentStatus.newIncident || IncidentStatus.alerted => AppColors.sosRed,
      IncidentStatus.accepted || IncidentStatus.onScene => AppColors.vvuGold,
      IncidentStatus.resolved => AppColors.safeGreen,
      IncidentStatus.falseAlarm => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
