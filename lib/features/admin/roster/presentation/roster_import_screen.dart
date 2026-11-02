import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../data/admin_repository.dart';
import '../../data/roster_csv.dart';
import '../../providers.dart';
import 'widgets/roster_preview.dart';

/// Imports the Registry's list of student and staff IDs (PRD §4.11), which
/// `verifyId` checks when someone registers.
class RosterImportScreen extends ConsumerStatefulWidget {
  const RosterImportScreen({super.key});

  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  String? _fileName;
  RosterCsv? _parsed;
  RosterImportResult? _result;
  String? _error;
  bool _busy = false;

  Future<void> _chooseFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return;
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    setState(() {
      _fileName = file.name;
      _parsed = parseRosterCsv(text);
      _result = null;
      _error = null;
    });
  }

  Future<void> _import() async {
    final rows = _parsed?.rows ?? const [];
    if (rows.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(adminRepositoryProvider).importRoster(rows);
      setState(() {
        _result = result;
        _parsed = null;
      });
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final parsed = _parsed;
    final result = _result;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ID roster', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Students and staff can only register with an ID on this list. '
          'Upload a CSV file with the columns idNumber, fullName, type and '
          'department, where type is student or staff. A fifth column, '
          'active, can be set to false to block an ID. A header row is '
          'optional. IDs that are already on the list are updated and stay '
          'linked to their accounts.',
        ),
        const SizedBox(height: 8),
        Text(
          'Example: 223IT0100001,Kwame Mensah,student,Information Technology',
          style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _chooseFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose CSV file'),
            ),
            if (_fileName != null) Text(_fileName!),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          FormMessage(_error!),
        ],
        if (parsed != null) ...[
          const SizedBox(height: 16),
          RosterPreview(parsed: parsed),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _busy || parsed.rows.isEmpty ? null : _import,
              icon: const Icon(Icons.cloud_upload),
              label: Text(
                _busy ? 'Importing…' : 'Import ${parsed.rows.length} IDs',
              ),
            ),
          ),
        ],
        if (result != null) ...[
          const SizedBox(height: 16),
          FormMessage(
            'Imported ${result.imported} IDs.'
            '${result.rejectedCount == 0 ? '' : ' ${result.rejectedCount} rows were skipped.'}',
            isError: false,
          ),
          for (final line in result.rejected) Text(line),
        ],
      ],
    );
  }
}
