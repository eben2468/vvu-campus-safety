import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/announcement.dart';
import '../../routing/routes.dart';
import '../../services/api_client.dart';
import '../../services/firestore_service.dart';
import '../../services/messaging_service.dart';
import '../auth/data/session.dart';
import '../auth/providers.dart';
import 'data/announcement_repository.dart';
import 'data/push_repository.dart';

final pushRepositoryProvider = Provider<PushRepository>((ref) {
  return PushRepository(
    ref.watch(messagingServiceProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// Registers this device for push whenever a user is signed in on mobile.
/// Watched by the root widget so it stays alive.
final pushRegistrationProvider = Provider<void>((ref) {
  if (kIsWeb) return;
  // Only re-run when the user or role changes, not on every profile update.
  final (uid, role) = ref.watch(
    sessionProvider.select(
      (s) => s.status == SessionStatus.active
          ? (s.profile?.uid, s.role)
          : (null, null),
    ),
  );
  if (uid == null || role == null) return;

  final push = ref.watch(pushRepositoryProvider);
  push.registerDevice(uid, role);
  ref.onDispose(push.stopListening);
});

/// Where to go when a push notification is tapped.
String routeForPush(Map<String, dynamic> data) {
  final incidentId = data['incidentId'] as String?;
  return switch (data['type']) {
    'sos' ||
    'report' when incidentId != null => Routes.incidentAlert(incidentId),
    'status' when incidentId != null => Routes.reportDetail(incidentId),
    'message' when incidentId != null => Routes.chat(incidentId),
    'announcement' => Routes.announcements,
    _ => Routes.splash, // the router sends the user to their home screen
  };
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(
    ref.watch(firestoreProvider),
    ref.watch(apiClientProvider),
  );
});

/// Announcements for the signed-in user's role, newest first.
final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final role = ref.watch(sessionProvider.select((s) => s.role));
  if (role == null) return Stream.value(const []);
  return ref.watch(announcementRepositoryProvider).watchFor(role);
});
