import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../data/admin_repository.dart';
import '../../data/roster_csv.dart';
import '../../providers.dart';
import '../../widgets/page_header.dart';
import 'widgets/roster_guide.dart';
import 'widgets/roster_preview.dart';
import 'widgets/roster_upload.dart';

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
    final parsed = _parsed;
    final upload = RosterUpload(
      fileName: _fileName,
      parsed: parsed,
      result: _result,
      busy: _busy,
      onChoose: _chooseFile,
      onImport: _import,
    );

    return ListView(
      padding: kPagePadding,
      children: [
        const PageHeader(
          title: 'ID roster',
          subtitle:
              'Students and staff can only register with an ID on this '
              'list.',
        ),
        if (_error != null) FormMessage(_error!),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1000) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  upload,
                  const SizedBox(height: kGap),
                  const RosterGuide(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: RosterGuide()),
                const SizedBox(width: kGap),
                Expanded(child: upload),
              ],
            );
          },
        ),
        if (parsed != null) ...[
          const SizedBox(height: kGap),
          RosterPreview(parsed: parsed),
        ],
      ],
    );
  }
}
