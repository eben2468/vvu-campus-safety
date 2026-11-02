import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../models/incident_status.dart';

/// Coloured label for an incident's status. The text colours all reach the
/// WCAG 4.5:1 contrast ratio on the chip's pale background
/// (test/core/contrast_test.dart).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final IncidentStatus status;

  static Color colorFor(IncidentStatus status) => switch (status) {
    IncidentStatus.newIncident || IncidentStatus.alerted => AppColors.sosRed,
    IncidentStatus.accepted || IncidentStatus.onScene => AppColors.inProgress,
    IncidentStatus.resolved => AppColors.safeGreen,
    IncidentStatus.falseAlarm => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
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
