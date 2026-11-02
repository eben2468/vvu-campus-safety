import 'package:flutter/material.dart';

import '../../../data/roster_csv.dart';

/// What a chosen CSV file will import: the first rows and any lines that
/// will be skipped.
class RosterPreview extends StatelessWidget {
  const RosterPreview({super.key, required this.parsed});

  final RosterCsv parsed;

  static const _previewRows = 10;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rows = parsed.rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${rows.length} IDs ready to import',
          style: textTheme.titleMedium,
        ),
        if (rows.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID number')),
                DataColumn(label: Text('Full name')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Department')),
                DataColumn(label: Text('Active')),
              ],
              rows: [
                for (final row in rows.take(_previewRows))
                  DataRow(
                    cells: [
                      DataCell(Text(row.idNumber)),
                      DataCell(Text(row.fullName)),
                      DataCell(Text(row.type)),
                      DataCell(Text(row.department)),
                      DataCell(Text(row.active ? 'Yes' : 'No')),
                    ],
                  ),
              ],
            ),
          ),
        if (rows.length > _previewRows)
          Text('…and ${rows.length - _previewRows} more.'),
        if (parsed.errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${parsed.errors.length} lines will be skipped:',
            style: textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          for (final error in parsed.errors.take(50)) Text(error),
          if (parsed.errors.length > 50)
            Text('…and ${parsed.errors.length - 50} more.'),
        ],
      ],
    );
  }
}
