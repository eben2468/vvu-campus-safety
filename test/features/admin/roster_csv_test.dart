import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/admin/data/roster_csv.dart';

void main() {
  group('parseRosterCsv', () {
    test('skips the header and normalises IDs and types', () {
      final csv = parseRosterCsv(
        'idNumber,fullName,type,department\r\n'
        '223it 0100001,Kwame Mensah,Student,Information Technology\r\n'
        'STF00012,Efua Addo,staff,Registry\r\n',
      );
      expect(csv.errors, isEmpty);
      expect(csv.rows, hasLength(2));
      expect(csv.rows.first.idNumber, '223IT0100001');
      expect(csv.rows.first.type, 'student');
      expect(csv.rows.last.toMap(), {
        'idNumber': 'STF00012',
        'fullName': 'Efua Addo',
        'type': 'staff',
        'department': 'Registry',
        'active': true,
      });
    });

    test('handles quoted fields with commas and quotes', () {
      final csv = parseRosterCsv(
        '224BA0300042,"Asante, Kofi ""KA""",student,"Business, Admin"',
      );
      expect(csv.rows.single.fullName, 'Asante, Kofi "KA"');
      expect(csv.rows.single.department, 'Business, Admin');
    });

    test('reads the optional active column', () {
      final csv = parseRosterCsv(
        '219IT0100088,Ama Sarpong,student,IT,false\n'
        '221TH0400007,Akosua Boateng,student,Theology,TRUE',
      );
      expect(csv.rows.map((r) => r.active), [false, true]);
    });

    test('reports bad lines by number and ignores blank ones', () {
      final csv = parseRosterCsv(
        '﻿idNumber,fullName,type,department\n' // Excel's byte-order mark
        '223IT0100001,Kwame Mensah,visitor,IT\n'
        '\n'
        'only-two,columns\n'
        ',No ID,student,IT\n'
        '223IT0100002,Yaw Darko,student,IT,maybe\n',
      );
      expect(csv.rows, isEmpty);
      expect(csv.errors, [
        'Line 2: type must be student or staff.',
        'Line 4: expected idNumber, fullName, type, department.',
        'Line 5: ID number and full name are required.',
        'Line 6: active must be true or false.',
      ]);
    });

    test('allows the department to be left out', () {
      final csv = parseRosterCsv('STF00031,Kwesi Appiah,staff');
      expect(csv.rows.single.department, '');
    });
  });

  test('the downloadable sample imports cleanly', () {
    final parsed = parseRosterCsv(sampleRosterCsv);
    expect(parsed.errors, isEmpty);
    expect(parsed.rows, hasLength(6)); // the guide says "6 example rows"
    expect(parsed.rows.map((r) => r.fullName), contains('Mensah, Adwoa'));
    expect(parsed.rows.where((r) => !r.active), hasLength(1));
    expect(parsed.rows.where((r) => r.type == 'staff'), hasLength(2));
  });
}
