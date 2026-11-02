import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/models/app_settings.dart';
import 'package:vvu_campus_safety/models/incident.dart';
import 'package:vvu_campus_safety/models/incident_event.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

void main() {
  const campus = GeoPoint(5.793, -0.122);

  group('Incident', () {
    final map = <String, dynamic>{
      'kind': 'sos',
      'category': 'emergency',
      'description': '',
      'status': 'on_scene',
      'reporterId': 'kwame',
      'reporterName': 'Kwame Mensah',
      'reporterPhone': '+233241234567',
      'location': campus,
      'geohash': 'ebzz',
      'lastLocation': const GeoPoint(5.794, -0.121),
      'locationLabel': 'Hostels',
      'mediaUrls': <String>[],
      'assignedTo': ['officer1'],
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2, 10)),
      'acknowledgedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2, 10, 1)),
      'resolvedAt': null,
      'responseSeconds': 60,
      'active': true,
      'cancelledByReporter': false,
    };

    test('round-trips a Firestore document', () {
      final incident = Incident.fromMap('s1', map);
      expect(incident.kind, IncidentKind.sos);
      expect(incident.status, IncidentStatus.onScene);
      expect(incident.responseSeconds, 60);
      expect(incident.toMap(), map);
    });

    test('currentLocation prefers the live position', () {
      final incident = Incident.fromMap('s1', map);
      expect(incident.currentLocation, const GeoPoint(5.794, -0.121));
      final noLive = Incident.fromMap('s2', {...map, 'lastLocation': null});
      expect(noLive.currentLocation, campus);
    });

    test('pendingSync comes from snapshot metadata', () {
      expect(
        Incident.fromMap('s1', map, pendingSync: true).pendingSync,
        isTrue,
      );
      expect(
        Incident.fromMap('s1', map).toMap().containsKey('pendingSync'),
        isFalse,
      );
    });
  });

  test('IncidentEvent round-trips', () {
    final map = {
      'type': 'on_scene',
      'actorId': 'officer1',
      'actorName': 'Test Officer',
      'text': 'Arrived',
      'timestamp': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
    };
    final event = IncidentEvent.fromMap('e1', map);
    expect(event.type, IncidentEventType.onScene);
    expect(event.toMap(), map);
  });

  group('AppSettings', () {
    test('defaults when the document is empty', () {
      final settings = AppSettings.fromMap({});
      expect(settings.categories, defaultCategories);
      expect(settings.sosCountdownSec, defaultSosCountdownSec);
      expect(settings.securityPhone, isEmpty);
    });

    test('labels a point with the zone it falls in', () {
      final settings = AppSettings.fromMap({
        'zones': [
          {'name': 'Hostels', 'center': campus, 'radiusM': 100},
        ],
      });
      expect(settings.zoneNameFor(const GeoPoint(5.7932, -0.1221)), 'Hostels');
      expect(settings.zoneNameFor(const GeoPoint(5.80, -0.13)), isNull);
    });
  });
}
