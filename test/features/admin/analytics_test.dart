import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/features/admin/data/analytics.dart';
import 'package:vvu_campus_safety/features/admin/data/settings_text.dart';
import 'package:vvu_campus_safety/models/audit_log_entry.dart';
import 'package:vvu_campus_safety/models/emergency_contact.dart';
import 'package:vvu_campus_safety/models/incident.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

Incident incident(
  String id, {
  IncidentKind kind = IncidentKind.report,
  String category = 'Theft',
  GeoPoint? location,
  DateTime? createdAt,
  int? responseSeconds,
  String description = '',
}) => Incident(
  id: id,
  kind: kind,
  status: IncidentStatus.resolved,
  reporterId: 'kwame',
  reporterName: 'Kwame Mensah',
  reporterPhone: '+233241234567',
  category: kind == IncidentKind.sos ? sosCategory : category,
  location: location,
  createdAt: createdAt,
  responseSeconds: responseSeconds,
  description: description,
);

void main() {
  group('heatCells', () {
    test('groups nearby incidents and skips ones without a location', () {
      final cells = heatCells([
        incident('a', location: const GeoPoint(5.79301, -0.12201)),
        incident('b', location: const GeoPoint(5.79302, -0.12202)),
        incident('c', location: const GeoPoint(5.7960, -0.1190)), // ~450 m away
        incident('d'),
      ]);
      expect(cells.map((c) => c.count), [2, 1]); // busiest first
      expect(cells.first.latitude, closeTo(5.793, 0.001));
    });
  });

  test('countByCategory puts SOS under its own label', () {
    final counts = countByCategory([
      incident('a'),
      incident('b'),
      incident('c', kind: IncidentKind.sos),
    ]);
    expect(counts.map((e) => '${e.key}:${e.value}'), ['Theft:2', 'SOS:1']);
  });

  group('weeks', () {
    test('weeks start on Monday in Accra time', () {
      // Sunday 8 Nov 2026 belongs to the week of Monday 2 Nov.
      expect(
        weekStart(DateTime.utc(2026, 11, 8, 23)),
        DateTime.utc(2026, 11, 2),
      );
      expect(weekStart(DateTime.utc(2026, 11, 9)), DateTime.utc(2026, 11, 9));
    });

    test('weeklyStats fills empty weeks and averages response times', () {
      final weeks = weeklyStats(
        [
          incident(
            'a',
            createdAt: DateTime.utc(2026, 10, 20),
            responseSeconds: 60,
          ),
          incident(
            'b',
            createdAt: DateTime.utc(2026, 10, 21),
            responseSeconds: 180,
          ),
          incident('c', createdAt: DateTime.utc(2026, 11, 3)),
        ],
        from: DateTime.utc(2026, 10, 19),
        to: DateTime.utc(2026, 11, 4),
      );
      expect(weeks.map((w) => w.count), [2, 0, 1]);
      expect(weeks.first.avgResponse, const Duration(minutes: 2));
      expect(weeks.last.avgResponse, isNull);
    });
  });

  group('incidentsCsv', () {
    test('writes a header and one row per incident', () {
      final csv = incidentsCsv([
        incident(
          'x1',
          createdAt: DateTime.utc(2026, 11, 2, 10, 5),
          location: const GeoPoint(5.793, -0.122),
          description: 'Phone taken, near "the" gate',
        ),
      ]);
      final lines = csv.trim().split('\r\n');
      expect(lines, hasLength(2));
      expect(lines.first, startsWith('id,raised (Africa/Accra),type'));
      expect(lines.last, contains('x1,"2 Nov 2026, 10:05",report,Theft'));
      expect(lines.last, contains('+233241234567'));
      expect(lines.last, contains('5.793,-0.122'));
      expect(lines.last, endsWith('"Phone taken, near ""the"" gate"'));
    });

    test('stops spreadsheet formulas in text fields', () {
      final csv = incidentsCsv([incident('x', description: '=HYPERLINK("x")')]);
      expect(csv, contains('"\'=HYPERLINK(""x"")"'));
    });
  });

  group('settings text', () {
    test('boundary round-trips and needs three points', () {
      final parsed = parseBoundary(
        '5.797, -0.126\n\n5.797,-0.118\n5.789, -0.118',
      );
      expect(parsed.error, isNull);
      expect(parseBoundary(boundaryToText(parsed.value!)).value, hasLength(3));
      expect(parseBoundary('5.797, -0.126\n5.797, -0.118').error, isNotNull);
      expect(parseBoundary('').value, isEmpty);
      expect(parseBoundary('5.797; -0.126').error, contains('line 1'));
    });

    test('zones allow commas in the name and check the radius', () {
      final parsed = parseZones('Hostels, Block A, 5.795, -0.124, 150');
      expect(parsed.value!.single.name, 'Hostels, Block A');
      expect(parsed.value!.single.radiusM, 150);
      expect(
        parseZones(zonesToText(parsed.value!)).value!.single.name,
        'Hostels, Block A',
      );
      expect(parseZones('Gate, 5.79, -0.12, 5').error, contains('radius'));
      expect(parseZones('5.79, -0.12, 50').error, isNotNull);
    });
  });

  test('audit entries read as sentences', () {
    String nameOf(String uid) => uid == 'u1' ? 'Yaw Darko' : uid;
    AuditLogEntry entry(String action, Map<String, dynamic> details) =>
        AuditLogEntry(
          id: '1',
          actorId: 'a',
          action: action,
          target: 'u1',
          details: details,
        );
    expect(
      entry('role_changed', {
        'from': 'student',
        'to': 'officer',
      }).describe(nameOf),
      'Changed Yaw Darko from student to officer.',
    );
    expect(
      entry('roster_imported', {'imported': 2, 'rejected': 1}).describe(nameOf),
      'Imported 2 IDs into the roster (1 rows skipped).',
    );
    expect(
      entry('settings_updated', {
        'fields': ['zones', 'securityPhone'],
      }).describe(nameOf),
      'Changed settings: zones, securityPhone.',
    );
  });

  test('EmergencyContact round-trips through a map', () {
    final contact = EmergencyContact.fromMap('c1', {
      'name': 'Ama Mensah',
      'phone': '+233201234567',
      'relationship': 'Mother',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
    });
    expect(contact.toMap()['phone'], '+233201234567');
    expect(contact.copyWith(relationship: 'Mum').relationship, 'Mum');
    expect(contact.copyWith(relationship: 'Mum').name, 'Ama Mensah');
  });
}
