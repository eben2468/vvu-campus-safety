import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../models/announcement.dart';

/// Reads campus announcements. Admins post them from the dashboard
/// (Milestone 5); `onAnnouncementCreated` pushes each one to its topic.
class AnnouncementRepository {
  AnnouncementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Announcements for [role], newest first. The `audience` filter is
  /// required: firestore.rules only allows reading your own audiences.
  Stream<List<Announcement>> watchFor(UserRole role, {int limit = 50}) {
    return _firestore
        .collection(Collections.announcements)
        .where(
          'audience',
          whereIn: [for (final a in Announcement.visibleTo(role)) a.name],
        )
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              Announcement.fromMap(doc.id, doc.data()),
          ],
        );
  }
}
