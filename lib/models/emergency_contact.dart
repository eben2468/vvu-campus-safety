import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Someone to text when the user presses SOS (PRD §4.10):
/// `users/{uid}/contacts/{contactId}`.
@immutable
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = '',
    this.createdAt,
  });

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String name;

  /// E.164, e.g. `+233241234567`.
  final String phone;

  /// e.g. "Mother", "Room mate". May be empty.
  final String relationship;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
  };

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) => EmergencyContact(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    relationship: relationship ?? this.relationship,
    createdAt: createdAt,
  );
}
