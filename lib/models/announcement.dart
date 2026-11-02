import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// A campus safety announcement from the Security Office:
/// `announcements/{id}`.
@immutable
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.audience = AnnouncementAudience.all,
    this.createdBy = '',
    this.createdAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      audience: AnnouncementAudience.fromValue(
        map['audience'] as String? ?? AnnouncementAudience.all.name,
      ),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;

  /// uid of the admin who posted it.
  final String createdBy;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'audience': audience.name,
    'createdBy': createdBy,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
  };

  Announcement copyWith({
    String? title,
    String? body,
    AnnouncementAudience? audience,
  }) => Announcement(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    audience: audience ?? this.audience,
    createdBy: createdBy,
    createdAt: createdAt,
  );

  /// Audiences a user with [role] sees: everything for "all" plus their
  /// own group. Admins see every announcement.
  static List<AnnouncementAudience> visibleTo(UserRole role) => switch (role) {
    UserRole.student => [
      AnnouncementAudience.all,
      AnnouncementAudience.students,
    ],
    UserRole.staff => [AnnouncementAudience.all, AnnouncementAudience.staff],
    UserRole.officer => [
      AnnouncementAudience.all,
      AnnouncementAudience.officers,
    ],
    UserRole.admin => AnnouncementAudience.values,
  };
}
