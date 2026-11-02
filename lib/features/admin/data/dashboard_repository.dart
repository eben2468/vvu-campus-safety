import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../models/audit_log_entry.dart';
import '../../../models/incident.dart';
import '../../../models/incident_event.dart';

/// A timeline entry from any incident, for the live board's activity feed.
@immutable
class ActivityItem {
  const ActivityItem({required this.incidentId, required this.event});

  final String incidentId;
  final IncidentEvent event;
}

/// Read-only incident queries for the admin dashboard.
class DashboardRepository {
  DashboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(Collections.incidents);

  /// Incidents raised since [since], newest first (summary cards).
  Stream<List<Incident>> watchSince(DateTime since) {
    return _incidents
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map(_toIncidents);
  }

  /// The [limit] most recent incidents, newest first. The incidents table
  /// filters these in the app; older ones are for the analytics pages.
  Stream<List<Incident>> watchRecent({int limit = 300}) {
    return _incidents
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_toIncidents);
  }

  /// Incidents raised from [from] up to (not including) [to], newest first,
  /// for the analytics page. Capped at 5000.
  Stream<List<Incident>> watchBetween(DateTime from, DateTime to) {
    return _incidents
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThan: Timestamp.fromDate(to))
        .orderBy('createdAt', descending: true)
        .limit(5000)
        .snapshots()
        .map(_toIncidents);
  }

  /// The most recent admin actions, newest first.
  Stream<List<AuditLogEntry>> watchAuditLogs({int limit = 200}) {
    return _firestore
        .collection(Collections.auditLogs)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              AuditLogEntry.fromMap(doc.id, doc.data()),
          ],
        );
  }

  /// The latest timeline entries across all incidents (a collection-group
  /// query on `events`).
  Stream<List<ActivityItem>> watchRecentActivity({int limit = 15}) {
    return _firestore
        .collectionGroup(Collections.events)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              ActivityItem(
                // events live at incidents/{incidentId}/events/{eventId}
                incidentId: doc.reference.parent.parent!.id,
                event: IncidentEvent.fromMap(doc.id, doc.data()),
              ),
          ],
        );
  }

  static List<Incident> _toIncidents(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) => [
    for (final doc in snap.docs)
      Incident.fromMap(
        doc.id,
        doc.data(),
        pendingSync: doc.metadata.hasPendingWrites,
      ),
  ];
}
