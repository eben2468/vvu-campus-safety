import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// A user's profile: the `users/{uid}` document.
///
/// [role] mirrors the Auth custom claim for display and search only — access
/// decisions always use the claim itself (docs/ARCHITECTURE.md §2).
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.idNumber,
    this.role,
    this.verified = false,
    this.onDuty = false,
    this.fcmTokens = const [],
    this.falseAlarmCount = 0,
    this.deactivated = false,
    this.createdAt,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      idNumber: map['idNumber'] as String?,
      role: UserRole.fromValue(map['role'] as String?),
      verified: map['verified'] as bool? ?? false,
      onDuty: map['onDuty'] as bool? ?? false,
      fcmTokens: List<String>.from(map['fcmTokens'] as List? ?? const []),
      falseAlarmCount: (map['falseAlarmCount'] as num?)?.toInt() ?? 0,
      deactivated: map['deactivated'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Document id.
  final String uid;
  final String fullName;
  final String email;

  /// E.164, e.g. `+233241234567`.
  final String phone;

  /// VVU ID number; null for officers and admins created by an admin.
  final String? idNumber;
  final UserRole? role;
  final bool verified;
  final bool onDuty;
  final List<String> fcmTokens;
  final int falseAlarmCount;
  final bool deactivated;
  final DateTime? createdAt;

  /// First word of the full name, for greetings.
  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'idNumber': idNumber,
    'role': role?.name,
    'verified': verified,
    'onDuty': onDuty,
    'fcmTokens': fcmTokens,
    'falseAlarmCount': falseAlarmCount,
    'deactivated': deactivated,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
  };

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? idNumber,
    UserRole? role,
    bool? verified,
    bool? onDuty,
    List<String>? fcmTokens,
    int? falseAlarmCount,
    bool? deactivated,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      role: role ?? this.role,
      verified: verified ?? this.verified,
      onDuty: onDuty ?? this.onDuty,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      falseAlarmCount: falseAlarmCount ?? this.falseAlarmCount,
      deactivated: deactivated ?? this.deactivated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
