/// App-wide constants: Firestore collection names, fixed enums and defaults.
///
/// Names here must match `docs/ARCHITECTURE.md` §3 exactly. The incident
/// status enum lives in `models/incident_status.dart` because it carries
/// transition logic.
library;

/// Firestore collection and sub-collection names.
abstract final class Collections {
  static const idRoster = 'idRoster';
  static const users = 'users';
  static const contacts = 'contacts'; // users/{uid}/contacts
  static const incidents = 'incidents';
  static const locations = 'locations'; // incidents/{id}/locations
  static const events = 'events'; // incidents/{id}/events
  static const messages = 'messages'; // incidents/{id}/messages
  static const announcements = 'announcements';
  static const auditLogs = 'auditLogs';
  static const settings = 'settings';

  /// The single app settings document: `settings/app`.
  static const appSettingsDoc = 'app';
}

/// Storage folder for incident photos: `incidents/{incidentId}/{file}`.
const storageIncidentsFolder = 'incidents';

/// User role, read from the Firebase Auth `role` custom claim.
enum UserRole {
  student,
  staff,
  officer,
  admin;

  /// Parses a claim value; returns null for a missing or unknown role.
  static UserRole? fromValue(String? value) {
    for (final role in values) {
      if (role.name == value) return role;
    }
    return null;
  }

  /// Students and staff are "members" who raise SOS and reports.
  bool get isMember => this == student || this == staff;

  /// Admins can do everything an officer can.
  bool get isOfficer => this == officer || this == admin;
}

/// Whether an incident is a one-tap SOS or a written report.
enum IncidentKind {
  sos,
  report;

  static IncidentKind fromValue(String value) =>
      values.firstWhere((k) => k.name == value);
}

/// Type of an `incidents/{id}/events` document.
enum IncidentEventType {
  created('created'),
  alerted('alerted'),
  accepted('accepted'),
  assigned('assigned'),
  onScene('on_scene'),
  note('note'),
  resolved('resolved'),
  falseAlarm('false_alarm'),
  cancelled('cancelled');

  const IncidentEventType(this.value);

  /// The string stored in Firestore.
  final String value;

  static IncidentEventType fromValue(String value) =>
      values.firstWhere((t) => t.value == value);
}

/// Who an announcement is pushed to. Each value is also an FCM topic name.
enum AnnouncementAudience {
  all,
  students,
  staff,
  officers;

  static AnnouncementAudience fromValue(String value) =>
      values.firstWhere((a) => a.name == value);
}

/// Category stored on SOS incidents.
const sosCategory = 'emergency';

/// Report categories used until `settings/app` is loaded.
const defaultCategories = [
  'Theft',
  'Assault',
  'Harassment',
  'Medical',
  'Fire',
  'Accident',
  'Suspicious activity',
  'Other',
];

/// Seconds the SOS countdown runs before sending (`settings/app.sosCountdownSec`).
const defaultSosCountdownSec = 3;

/// Maximum photos on one incident report.
const maxIncidentPhotos = 3;

/// Maximum emergency contacts per user.
const maxEmergencyContacts = 5;

/// Android notification channel for SOS and report alerts.
const sosAlertsChannelId = 'sos_alerts';

/// Display timezone. Africa/Accra is UTC+0 with no daylight saving.
const campusTimeZone = 'Africa/Accra';

/// Default map centre: VVU Oyibi campus (approximate, until zones are set).
const campusCenterLat = 5.7930;
const campusCenterLng = -0.1220;

/// Largest photo we upload after compression (DECISIONS.md D5).
const maxPhotoBytes = 1024 * 1024;

/// Allowed length of an incident report description (PRD §4.3).
const minDescriptionLength = 10;
const maxDescriptionLength = 1000;
