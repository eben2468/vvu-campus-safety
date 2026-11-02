import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One admin action: an `auditLogs/{id}` document, written only by the
/// admin Cloud Functions.
@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.action,
    required this.target,
    this.details = const {},
    this.timestamp,
  });

  factory AuditLogEntry.fromMap(String id, Map<String, dynamic> map) {
    return AuditLogEntry(
      id: id,
      actorId: map['actorId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      target: map['target'] as String? ?? '',
      details: Map<String, dynamic>.from(map['details'] as Map? ?? const {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  final String id;

  /// uid of the admin.
  final String actorId;

  /// e.g. `role_changed`, `roster_imported`, `settings_updated`.
  final String action;

  /// A user's uid, `idRoster` or `settings/app`.
  final String target;
  final Map<String, dynamic> details;
  final DateTime? timestamp;

  /// A sentence for the audit log page. [nameOf] turns a uid into a name.
  String describe(String Function(String uid) nameOf) {
    final who = nameOf(target);
    return switch (action) {
      'user_created' =>
        'Created ${details['role'] ?? 'an'} account for ${details['email'] ?? who}.',
      'role_changed' =>
        'Changed $who from ${details['from'] ?? 'no role'} to ${details['to']}.',
      'user_deactivated' => 'Deactivated $who.',
      'user_reactivated' => 'Reactivated $who.',
      'roster_imported' =>
        'Imported ${details['imported'] ?? 0} IDs into the roster'
            '${(details['rejected'] ?? 0) == 0 ? '' : ' (${details['rejected']} rows skipped)'}.',
      'settings_updated' =>
        'Changed settings: ${(details['fields'] as List? ?? const []).join(', ')}.',
      _ => '$action on $who.',
    };
  }
}
