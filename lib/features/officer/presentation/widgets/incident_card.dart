import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/incident.dart';
import '../../../incidents/presentation/widgets/status_chip.dart';

/// One row in the officer's alert queue.
class IncidentCard extends StatelessWidget {
  const IncidentCard({super.key, required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = incident.createdAt;
    final details = [
      incident.locationLabel ??
          (incident.currentLocation == null ? 'No location' : 'On campus map'),
      if (createdAt != null) timeAgo(createdAt),
    ].join(' · ');

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: incident.isSos
              ? AppColors.sosRed
              : AppColors.vvuBlue,
          foregroundColor: Colors.white,
          child: Icon(incident.isSos ? Icons.sos : Icons.report),
        ),
        title: Text(
          incident.isSos
              ? 'SOS — ${incident.reporterName}'
              : '${incident.category} — ${incident.reporterName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(details),
        trailing: StatusChip(incident.status),
      ),
    );
  }
}
