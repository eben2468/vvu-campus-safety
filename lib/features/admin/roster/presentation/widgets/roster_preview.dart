import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../data/roster_csv.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/status_views.dart';

/// What a chosen CSV file will import: the first rows and any lines that
/// will be skipped.
class RosterPreview extends StatelessWidget {
  const RosterPreview({super.key, required this.parsed});

  final RosterCsv parsed;

  static const _previewRows = 10;

  @override
  Widget build(BuildContext context) {
    final rows = parsed.rows;
    final errors = parsed.errors;
    return SectionCard(
      title: 'Preview',
      subtitle: rows.length > _previewRows
          ? 'The first $_previewRows of ${rows.length} IDs'
          : '${rows.length} ID${rows.length == 1 ? '' : 's'} ready to import',
      icon: Icons.table_rows_outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errors.isNotEmpty) _Skipped(errors: errors),
          if (rows.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID NUMBER')),
                      DataColumn(label: Text('FULL NAME')),
                      DataColumn(label: Text('TYPE')),
                      DataColumn(label: Text('DEPARTMENT')),
                      DataColumn(label: Text('ACTIVE')),
                    ],
                    rows: [
                      for (final row in rows.take(_previewRows))
                        DataRow(
                          cells: [
                            DataCell(Text(row.idNumber)),
                            DataCell(Text(row.fullName)),
                            DataCell(
                              Pill(
                                row.type == 'staff' ? 'Staff' : 'Student',
                                color: AppColors.vvuBlue,
                              ),
                            ),
                            DataCell(Text(row.department)),
                            DataCell(
                              row.active
                                  ? const Pill(
                                      'Yes',
                                      color: AppColors.safeGreen,
                                    )
                                  : const Pill(
                                      'Blocked',
                                      color: AppColors.sosRed,
                                    ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The lines that won't be imported, and why.
class _Skipped extends StatelessWidget {
  const _Skipped({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sosRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${errors.length} line${errors.length == 1 ? '' : 's'} will be '
            'skipped:',
            style: const TextStyle(
              color: AppColors.sosRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          for (final error in errors.take(50)) Text(error),
          if (errors.length > 50) Text('…and ${errors.length - 50} more.'),
        ],
      ),
    );
  }
}
