import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/announcement.dart';
import '../../../services/api_client.dart';

/// Campus announcements. Admins post them from the dashboard;
/// the server then pushes each one to its topic.
class AnnouncementRepository {
  AnnouncementRepository(this._firestore, this._api);

  final FirebaseFirestore _firestore;
  final ApiClient _api;

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

  /// Posts an announcement as admin [byUid]. `onAnnouncementCreated` then
  /// pushes it to the audience's FCM topic.
  Future<void> post({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    required String byUid,
  }) async {
    try {
      final doc = await _firestore.collection(Collections.announcements).add({
        'title': title.trim(),
        'body': body.trim(),
        'audience': audience.name,
        'createdBy': byUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _api.notify('notifyAnnouncement', {'announcementId': doc.id});
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Only admins can post announcements.'
            : 'Could not post the announcement. Please try again.',
      );
    }
  }
}
