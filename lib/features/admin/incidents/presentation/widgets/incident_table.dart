import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../models/incident.dart';
import '../../../../incidents/presentation/widgets/status_chip.dart';
import '../../../widgets/status_views.dart';

/// Incidents as table rows; clicking a row calls [onOpen].
class IncidentTable extends StatelessWidget {
  const IncidentTable({
    super.key,
    required this.incidents,
    required this.onOpen,
  });

  final List<Incident> incidents;
  final void Function(Incident incident) onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            // Fill the card's width; scroll sideways only when too narrow.
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('RAISED')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('REPORTER')),
                DataColumn(label: Text('PLACE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('RESPONSE'), numeric: true),
              ],
              rows: [for (final incident in incidents) _row(incident)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(Incident incident) {
    final response = incident.responseSeconds;
    return DataRow(
      onSelectChanged: (_) => onOpen(incident),
      cells: [
        DataCell(
          Text(
            incident.createdAt == null
                ? 'Sending…'
                : formatDateTime(incident.createdAt!),
          ),
        ),
        DataCell(
          incident.isSos
              ? const Pill(
                  'SOS',
                  color: AppColors.sosRed,
                  icon: Icons.warning_amber_rounded,
                )
              : Pill(incident.category, color: AppColors.vvuBlue),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InitialsAvatar(incident.reporterName, radius: 15),
              const SizedBox(width: 10),
              Text(incident.reporterName),
            ],
          ),
        ),
        DataCell(Text(incident.locationLabel ?? '—')),
        DataCell(StatusChip(incident.status)),
        DataCell(
          Text(
            response == null
                ? '—'
                : formatDuration(Duration(seconds: response)),
          ),
        ),
      ],
    );
  }
}
