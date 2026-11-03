import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../../../services/file_download.dart';
import '../../../data/roster_csv.dart';
import '../../../widgets/section_card.dart';

/// How to prepare a roster file: the steps, the columns and a sample file
/// to download and fill in.
class RosterGuide extends StatelessWidget {
  const RosterGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      title: 'Prepare the file',
      subtitle: 'From the Registry (students) or HR (staff)',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SampleDownload(),
          const SizedBox(height: 16),
          const _Step(
            number: 1,
            text: 'Download the sample and open it in Excel or Google Sheets.',
          ),
          const _Step(
            number: 2,
            text:
                'Replace the example rows with your list, one person per '
                'row. Keep the header row.',
          ),
          const _Step(
            number: 3,
            text: 'Save as CSV (comma separated) and choose it on the right.',
          ),
          const SizedBox(height: 12),
          Text('Columns, in this order', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final column in rosterColumns)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          column.name,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          column.required ? 'Required' : 'Optional',
                          style: textTheme.labelSmall?.copyWith(
                            color: column.required
                                ? AppColors.vvuBlue
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(column.help)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Re-importing an updated list is safe: existing IDs are updated '
            'and stay linked to the accounts already registered with them.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// The sample file, highlighted as the place to start.
class _SampleDownload extends StatelessWidget {
  const _SampleDownload();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.vvuGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start from the sample file', style: textTheme.titleSmall),
              Text(
                'vvu-roster-sample.csv · 6 example rows',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: () =>
                downloadTextFile('vvu-roster-sample.csv', sampleRosterCsv),
            icon: const Icon(Icons.download),
            label: const Text('Download sample CSV'),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.vvuBlue,
            foregroundColor: Colors.white,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
