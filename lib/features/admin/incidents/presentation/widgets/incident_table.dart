import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../models/incident.dart';
import '../../../../incidents/presentation/widgets/status_chip.dart';

/// Incidents as table rows; tapping a row calls [onOpen].
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
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('Raised')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Reporter')),
            DataColumn(label: Text('Place')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Response'), numeric: true),
          ],
          rows: [
            for (final incident in incidents)
              DataRow(
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
                    Text(
                      incident.isSos ? 'SOS' : incident.category,
                      style: incident.isSos
                          ? const TextStyle(
                              color: AppColors.sosRed,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                  ),
                  DataCell(Text(incident.reporterName)),
                  DataCell(Text(incident.locationLabel ?? '—')),
                  DataCell(StatusChip(incident.status)),
                  DataCell(
                    Text(
                      incident.responseSeconds == null
                          ? '—'
                          : formatDuration(
                              Duration(seconds: incident.responseSeconds!),
                            ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
