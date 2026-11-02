import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/geo.dart';
import '../../../models/app_user.dart';
import '../../../models/incident.dart';
import '../../../models/incident_event.dart';
import '../../../models/incident_status.dart';

/// Reads and writes `incidents` and their `locations` / `events`.
///
/// Writes a reporter makes during an emergency (SOS, live location, "I'm
/// safe") never wait for the server: Firestore applies them to the local
/// cache at once and syncs when there is a connection.
class IncidentRepository {
  IncidentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// How long to wait for the server before treating a write as queued.
  static const serverAckTimeout = Duration(seconds: 6);

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(Collections.incidents);

  CollectionReference<Map<String, dynamic>> _events(String incidentId) =>
      _incidents.doc(incidentId).collection(Collections.events);

  /// Creates an SOS and returns its id. The `onIncidentCreated` function
  /// then marks it `alerted` and notifies on-duty officers.
  Future<String> createSos({
    required AppUser reporter,
    GeoPoint? location,
    String? locationLabel,
  }) async {
    final doc = _incidents.doc();
    await _commitOrQueue(
      doc.set(
        _newIncident(
          kind: IncidentKind.sos,
          category: sosCategory,
          description: '',
          reporter: reporter,
          location: location,
          locationLabel: locationLabel,
        ),
      ),
    );
    return doc.id;
  }

  /// A fresh id for a report, so photos can be uploaded under it before
  /// the incident document is written.
  String newIncidentId() => _incidents.doc().id;

  /// Creates a report (PRD §4.3) with already-uploaded photo URLs.
  Future<void> createReport({
    required String incidentId,
    required AppUser reporter,
    required String category,
    required String description,
    required List<String> mediaUrls,
    GeoPoint? location,
    String? locationLabel,
  }) {
    return _commitOrQueue(
      _incidents
          .doc(incidentId)
          .set(
            _newIncident(
              kind: IncidentKind.report,
              category: category,
              description: description,
              reporter: reporter,
              location: location,
              locationLabel: locationLabel,
              mediaUrls: mediaUrls,
            ),
          ),
    );
  }

  /// Everything the user has raised (SOS and reports), newest first.
  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map(_fromSnapshot).toList());
  }

  /// The document a reporter creates; must satisfy `validNewIncident()` in
  /// firestore.rules.
  static Map<String, dynamic> _newIncident({
    required IncidentKind kind,
    required String category,
    required String description,
    required AppUser reporter,
    GeoPoint? location,
    String? locationLabel,
    List<String> mediaUrls = const [],
  }) => {
    'kind': kind.name,
    'category': category,
    'description': description,
    'status': IncidentStatus.newIncident.value,
    'reporterId': reporter.uid,
    'reporterName': reporter.fullName,
    'reporterPhone': reporter.phone,
    'location': location,
    'geohash': location == null
        ? null
        : geohash(location.latitude, location.longitude),
    'lastLocation': location,
    'locationLabel': locationLabel,
    'mediaUrls': mediaUrls,
    'assignedTo': <String>[],
    'createdAt': FieldValue.serverTimestamp(),
    'active': true,
    'cancelledByReporter': false,
  };

  /// The reporter's open SOS, if any (a user may only have one).
  Stream<Incident?> watchMyActiveSos(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .where('kind', isEqualTo: IncidentKind.sos.name)
        .where('active', isEqualTo: true)
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => snap.docs.isEmpty ? null : _fromSnapshot(snap.docs.first),
        );
  }

  Stream<Incident?> watchIncident(String id) {
    return _incidents
        .doc(id)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.exists ? _fromSnapshot(snap) : null);
  }

  /// Open incidents for the officer queue: SOS first, then oldest first.
  Stream<List<Incident>> watchActiveIncidents() {
    return _incidents
        .where('active', isEqualTo: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs.map(_fromSnapshot).toList()..sort(_queueOrder),
        );
  }

  Stream<List<IncidentEvent>> watchEvents(String incidentId) {
    return _events(incidentId)
        .orderBy('timestamp')
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              IncidentEvent.fromMap(doc.id, doc.data()),
          ],
        );
  }

  /// Records one GPS fix during an active SOS (fire and forget).
  Future<void> addLocationFix(
    String incidentId, {
    required GeoPoint point,
    required double accuracy,
  }) {
    final incident = _incidents.doc(incidentId);
    final batch = _firestore.batch()
      ..set(incident.collection(Collections.locations).doc(), {
        'point': point,
        'accuracy': accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      })
      ..update(incident, {'lastLocation': point});
    return _commitOrQueue(batch.commit());
  }

  /// "I'm safe": the reporter closes their own SOS before an officer
  /// accepts it. Stored as `resolved` + `cancelledByReporter` (D9).
  Future<void> cancelSos(Incident incident, AppUser reporter) {
    if (!incident.status.canTransition(
      IncidentStatus.resolved,
      by: StatusActor.reporter,
    )) {
      throw const AppException(
        'An officer is already responding. Tell them you are safe by phone.',
      );
    }
    final ref = _incidents.doc(incident.id);
    final batch = _firestore.batch()
      ..update(ref, {
        'status': IncidentStatus.resolved.value,
        'cancelledByReporter': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'active': false,
      })
      ..set(_events(incident.id).doc(), {
        'type': IncidentEventType.cancelled.value,
        'actorId': reporter.uid,
        'actorName': reporter.fullName,
        'text': '${reporter.fullName} marked themselves safe.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    return _commitOrQueue(batch.commit());
  }

  /// An officer takes the alert. Runs in a transaction so two officers
  /// can't both accept it.
  Future<void> accept(String incidentId, AppUser officer) async {
    final ref = _incidents.doc(incidentId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final status = IncidentStatus.fromValue(
          snap.data()?['status'] as String? ?? 'new',
        );
        if (!status.canTransition(
          IncidentStatus.accepted,
          by: StatusActor.officer,
        )) {
          throw AppException(
            status == IncidentStatus.accepted
                ? 'Another officer has already accepted this alert.'
                : 'This alert can no longer be accepted.',
          );
        }
        tx.update(ref, {
          'status': IncidentStatus.accepted.value,
          'assignedTo': FieldValue.arrayUnion([officer.uid]),
          'acknowledgedAt': FieldValue.serverTimestamp(),
        });
        tx.set(_events(incidentId).doc(), {
          'type': IncidentEventType.accepted.value,
          'actorId': officer.uid,
          'actorName': officer.fullName,
          'text': '${officer.fullName} accepted the alert.',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw AppException(_officerError(e, 'accept the alert'));
    }
  }

  /// Moves an incident to on scene, resolved or false alarm (PRD §4.5).
  /// On scene and resolve are for officers assigned to the incident (or an
  /// admin); anyone on the security team may mark a false alarm. The
  /// `onIncidentUpdated` function then closes it and tells the reporter.
  Future<void> updateStatus(
    String incidentId,
    IncidentStatus to,
    AppUser officer, {
    String note = '',
  }) async {
    final ref = _incidents.doc(incidentId);
    try {
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? const <String, dynamic>{};
        final from = IncidentStatus.fromValue(
          data['status'] as String? ?? 'new',
        );
        final assignedTo = List<String>.from(
          data['assignedTo'] as List? ?? const [],
        );

        if (!from.canTransition(to, by: StatusActor.officer)) {
          throw AppException(
            'This incident is ${from.label.toLowerCase()} and cannot be marked '
            '${to.label.toLowerCase()}.',
          );
        }
        if (!canActOn(assignedTo, officer, to)) {
          throw const AppException(
            'Accept or be assigned to this incident first.',
          );
        }
        tx.update(ref, {'status': to.value});
        tx.set(_events(incidentId).doc(), {
          'type': _eventFor(to).value,
          'actorId': officer.uid,
          'actorName': officer.fullName,
          'text': _statusText(to, officer.fullName, note.trim()),
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw AppException(_officerError(e, 'update the incident'));
    }
  }

  /// Whether [officer] may move an incident with these assignees to [to]:
  /// mirrors `officerUpdate()` in firestore.rules.
  static bool canActOn(
    List<String> assignedTo,
    AppUser officer,
    IncidentStatus to,
  ) {
    if (to == IncidentStatus.falseAlarm) return true;
    return assignedTo.contains(officer.uid) || officer.role == UserRole.admin;
  }

  /// Adds another officer to the response team.
  Future<void> assign(
    String incidentId, {
    required AppUser assignee,
    required AppUser by,
  }) async {
    final batch = _firestore.batch()
      ..update(_incidents.doc(incidentId), {
        'assignedTo': FieldValue.arrayUnion([assignee.uid]),
      })
      ..set(_events(incidentId).doc(), {
        'type': IncidentEventType.assigned.value,
        'actorId': by.uid,
        'actorName': by.fullName,
        'text': '${by.fullName} assigned ${assignee.fullName}.',
        'timestamp': FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException(_officerError(e, 'assign the officer'));
    }
  }

  /// A note on the incident's timeline (e.g. what the officer found).
  Future<void> addNote(String incidentId, AppUser officer, String text) async {
    try {
      await _events(incidentId).add({
        'type': IncidentEventType.note.value,
        'actorId': officer.uid,
        'actorName': officer.fullName,
        'text': text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException(_officerError(e, 'save the note'));
    }
  }

  static IncidentEventType _eventFor(IncidentStatus status) => switch (status) {
    IncidentStatus.onScene => IncidentEventType.onScene,
    IncidentStatus.resolved => IncidentEventType.resolved,
    IncidentStatus.falseAlarm => IncidentEventType.falseAlarm,
    IncidentStatus.accepted => IncidentEventType.accepted,
    IncidentStatus.alerted => IncidentEventType.alerted,
    IncidentStatus.newIncident => IncidentEventType.created,
  };

  static String _statusText(IncidentStatus to, String name, String note) {
    final base = switch (to) {
      IncidentStatus.onScene => '$name arrived on scene.',
      IncidentStatus.resolved => '$name resolved the incident.',
      IncidentStatus.falseAlarm => '$name marked this as a false alarm.',
      _ => '$name changed the status to ${to.label.toLowerCase()}.',
    };
    return note.isEmpty ? base : '$base Note: $note';
  }

  static String _officerError(FirebaseException e, String action) =>
      switch (e.code) {
        'unavailable' => 'No connection. Check your data and try again.',
        'permission-denied' => 'You are not allowed to $action.',
        _ => 'Could not $action. Please try again.',
      };

  /// Waits briefly for the server; if it doesn't answer (e.g. offline) the
  /// write stays queued in the local cache and is sent later.
  Future<void> _commitOrQueue(Future<void> write) async {
    try {
      await write.timeout(serverAckTimeout);
    } on TimeoutException {
      // Queued offline — Firestore retries automatically.
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'You are not allowed to do that. Contact the Security Office.'
            : 'Something went wrong. Please try again or call security.',
      );
    }
  }

  static Incident _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) =>
      Incident.fromMap(
        snap.id,
        snap.data()!,
        pendingSync: snap.metadata.hasPendingWrites,
      );

  static int _queueOrder(Incident a, Incident b) {
    if (a.isSos != b.isSos) return a.isSos ? -1 : 1;
    final aTime = a.createdAt ?? DateTime.now();
    final bTime = b.createdAt ?? DateTime.now();
    return aTime.compareTo(bTime);
  }
}
