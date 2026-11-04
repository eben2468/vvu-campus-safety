import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One ID the Registry or HR supplied: an `idRoster/{idNumber}` document.
/// Admins read these; only the server API writes them.
@immutable
class RosterEntry {
  const RosterEntry({
    required this.idNumber,
    required this.fullName,
    required this.type,
    this.department = '',
    this.active = true,
    this.claimedBy,
    this.importedAt,
  });

  factory RosterEntry.fromMap(String id, Map<String, dynamic> map) {
    return RosterEntry(
      idNumber: id,
      fullName: map['fullName'] as String? ?? '',
      type: map['type'] as String? ?? '',
      department: map['department'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      claimedBy: map['claimedBy'] as String?,
      importedAt: (map['importedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String idNumber;
  final String fullName;

  /// `student` or `staff`.
  final String type;
  final String department;

  /// Inactive IDs can't register.
  final bool active;

  /// uid of the account registered with this ID.
  final String? claimedBy;
  final DateTime? importedAt;

  bool get isRegistered => claimedBy != null;
}
