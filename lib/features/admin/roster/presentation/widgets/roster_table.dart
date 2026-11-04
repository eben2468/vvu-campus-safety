import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../models/roster_entry.dart';
import '../../../widgets/status_views.dart';

/// Imported IDs as table rows.
class RosterTable extends StatelessWidget {
  const RosterTable({super.key, required this.entries});

  final List<RosterEntry> entries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID NUMBER')),
                DataColumn(label: Text('FULL NAME')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('DEPARTMENT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('IMPORTED')),
              ],
              rows: [for (final entry in entries) _row(entry)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(RosterEntry entry) {
    final importedAt = entry.importedAt;
    return DataRow(
      cells: [
        DataCell(Text(entry.idNumber)),
        DataCell(Text(entry.fullName)),
        DataCell(
          Pill(
            entry.type == 'staff' ? 'Staff' : 'Student',
            color: AppColors.vvuBlue,
          ),
        ),
        DataCell(Text(entry.department.isEmpty ? '—' : entry.department)),
        DataCell(_status(entry)),
        DataCell(Text(importedAt == null ? '—' : formatDateTime(importedAt))),
      ],
    );
  }

  static Widget _status(RosterEntry entry) {
    if (!entry.active) {
      return const Pill('Blocked', color: AppColors.sosRed, icon: Icons.block);
    }
    if (entry.isRegistered) {
      return const Pill('Registered', color: AppColors.safeGreen);
    }
    return const Pill('Not registered');
  }
}
