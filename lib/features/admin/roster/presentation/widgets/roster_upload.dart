import 'package:flutter/material.dart';

import '../../../../../core/theme.dart';
import '../../../data/admin_repository.dart';
import '../../../data/roster_csv.dart';
import '../../../widgets/section_card.dart';

/// Choosing the file, importing it, and the result of the last import.
class RosterUpload extends StatelessWidget {
  const RosterUpload({
    super.key,
    required this.fileName,
    required this.parsed,
    required this.result,
    required this.busy,
    required this.onChoose,
    required this.onImport,
  });

  final String? fileName;
  final RosterCsv? parsed;
  final RosterImportResult? result;
  final bool busy;
  final VoidCallback onChoose;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final parsed = this.parsed;
    final result = this.result;
    final ready = parsed?.rows.length ?? 0;

    return SectionCard(
      title: 'Upload',
      subtitle: 'Check the preview, then import',
      icon: Icons.upload_file_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The drop-zone look tells the admin where the file goes.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 40,
                  color: AppColors.vvuBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  fileName ?? 'No file chosen yet',
                  style: textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'CSV files only',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: busy ? null : onChoose,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    fileName == null ? 'Choose CSV file' : 'Choose another',
                  ),
                ),
              ],
            ),
          ),
          if (parsed != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: busy || ready == 0 ? null : onImport,
              icon: const Icon(Icons.cloud_done_outlined),
              label: Text(
                busy
                    ? 'Importing…'
                    : ready == 0
                    ? 'Nothing to import'
                    : 'Import $ready ID${ready == 1 ? '' : 's'}',
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            _ResultBox(result: result),
          ],
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.result});

  final RosterImportResult result;

  @override
  Widget build(BuildContext context) {
    final skipped = result.rejectedCount;
    final color = skipped == 0 ? AppColors.safeGreen : AppColors.inProgress;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Imported ${result.imported} IDs'
                  '${skipped == 0 ? '.' : ' · $skipped rows skipped:'}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          for (final line in result.rejected)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}
