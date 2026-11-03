import 'package:flutter/foundation.dart';

import '../../../core/utils/formatters.dart';

/// One row of an ID roster CSV, as sent to `adminImportRoster`.
@immutable
class RosterRow {
  const RosterRow({
    required this.idNumber,
    required this.fullName,
    required this.type,
    this.department = '',
    this.active = true,
  });

  final String idNumber;
  final String fullName;

  /// `student` or `staff`.
  final String type;
  final String department;
  final bool active;

  Map<String, dynamic> toMap() => {
    'idNumber': idNumber,
    'fullName': fullName,
    'type': type,
    'department': department,
    'active': active,
  };
}

/// A parsed roster file: the rows to import and the lines that were skipped.
@immutable
class RosterCsv {
  const RosterCsv({required this.rows, required this.errors});

  final List<RosterRow> rows;

  /// e.g. "Line 4: type must be student or staff."
  final List<String> errors;
}

/// A template the admin can download, fill in (e.g. in Excel) and import.
/// The names and IDs are made up.
const sampleRosterCsv = '''
idNumber,fullName,type,department,active
225IT0100101,Ama Owusu,student,Information Technology,true
225NU0200102,Kofi Boateng,student,Nursing,true
224BA0300103,"Mensah, Adwoa",student,Business Administration,true
223TH0400104,Yaw Asante,student,Theology,false
STF00201,Esi Appiah,staff,Registry,true
STF00202,Kwabena Darko,staff,Finance,true
''';

/// The columns of a roster file, for the guide on the import page.
const rosterColumns = [
  (
    name: 'idNumber',
    required: true,
    help: 'VVU ID, e.g. 225IT0100101 or STF00201',
  ),
  (
    name: 'fullName',
    required: true,
    help: 'As on the ID card. Quote names with commas',
  ),
  (name: 'type', required: true, help: 'student or staff'),
  (name: 'department', required: false, help: 'Faculty, department or office'),
  (
    name: 'active',
    required: false,
    help: 'false blocks the ID; empty means true',
  ),
];

/// Parses a roster CSV with the columns `idNumber,fullName,type,department`
/// and an optional fifth `active` column (`true`/`false`, default true).
///
/// A header row is skipped if present. Fields may be quoted ("Mensah, Kwame").
/// The function checks the rows again; this only catches what a spreadsheet
/// export typically gets wrong, so the admin sees problems before uploading.
RosterCsv parseRosterCsv(String text) {
  final rows = <RosterRow>[];
  final errors = <String>[];
  final lines = _csvRecords(text.replaceFirst('﻿', ''));

  for (final (lineNumber, fields) in lines) {
    if (fields.every((f) => f.trim().isEmpty)) continue; // blank line
    if (lineNumber == 1 && fields.first.trim().toLowerCase() == 'idnumber') {
      continue; // header
    }
    String error(String message) => 'Line $lineNumber: $message';

    if (fields.length < 3 || fields.length > 5) {
      errors.add(error('expected idNumber, fullName, type, department.'));
      continue;
    }
    final type = fields[2].trim().toLowerCase();
    if (type != 'student' && type != 'staff') {
      errors.add(error('type must be student or staff.'));
      continue;
    }
    final activeText = fields.length == 5 ? fields[4].trim().toLowerCase() : '';
    if (activeText.isNotEmpty &&
        activeText != 'true' &&
        activeText != 'false') {
      errors.add(error('active must be true or false.'));
      continue;
    }
    final idNumber = normalizeIdNumber(fields[0]);
    final fullName = fields[1].trim();
    if (idNumber.isEmpty || fullName.isEmpty) {
      errors.add(error('ID number and full name are required.'));
      continue;
    }
    rows.add(
      RosterRow(
        idNumber: idNumber,
        fullName: fullName,
        type: type,
        department: fields.length > 3 ? fields[3].trim() : '',
        active: activeText != 'false',
      ),
    );
  }
  return RosterCsv(rows: rows, errors: errors);
}

/// Splits CSV text into records of fields, with the line each record starts
/// on. Handles quoted fields, doubled quotes ("") and \r\n line endings.
List<(int, List<String>)> _csvRecords(String text) {
  final records = <(int, List<String>)>[];
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var line = 1;
  var recordLine = 1;

  void endField() {
    fields.add(field.toString());
    field.clear();
  }

  void endRecord() {
    endField();
    records.add((recordLine, fields));
    fields = <String>[];
    recordLine = line;
  }

  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (inQuotes) {
      if (char == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (char == '"') {
        inQuotes = false;
      } else {
        if (char == '\n') line++;
        field.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      endField();
    } else if (char == '\n') {
      line++;
      endRecord();
    } else if (char != '\r') {
      field.write(char);
    }
  }
  if (field.isNotEmpty || fields.isNotEmpty) endRecord();
  return records;
}
