import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../services/messaging_service.dart';
import '../../auth/data/user_repository.dart';

/// Links this device to the signed-in user for push: stores its push ID
/// (FCM installation ID) in `users/{uid}.fcmTokens` and subscribes to the
/// announcement topics.
class PushRepository {
  PushRepository(this._messaging, this._users);

  final MessagingService _messaging;
  final UserRepository _users;

  StreamSubscription<String>? _registrations;
  String? _currentId;

  /// FCM topic for a role's announcements (matches `AnnouncementAudience`).
  static String topicFor(UserRole role) => switch (role) {
    UserRole.student => AnnouncementAudience.students.name,
    UserRole.staff => AnnouncementAudience.staff.name,
    UserRole.officer || UserRole.admin => AnnouncementAudience.officers.name,
  };

  Future<void> registerDevice(String uid, UserRole role) async {
    await _registrations?.cancel();
    _registrations = _messaging.onRegistered.listen((id) {
      _currentId = id;
      _save(uid, id);
    });
    await _messaging.register();
    await _messaging.subscribe(AnnouncementAudience.all.name);
    await _messaging.subscribe(topicFor(role));
  }

  /// Stops listening for push ID changes (e.g. the user changed).
  Future<void> stopListening() async {
    await _registrations?.cancel();
    _registrations = null;
  }

  /// Called before sign-out so this phone stops receiving the user's alerts.
  Future<void> unregisterDevice(String uid, UserRole? role) async {
    await stopListening();
    final id = _currentId;
    if (id != null) {
      try {
        await _users.removeFcmToken(uid, id);
      } catch (e) {
        debugPrint('Could not remove push ID: $e');
      }
    }
    _currentId = null;
    await _messaging.unsubscribe(AnnouncementAudience.all.name);
    if (role != null) await _messaging.unsubscribe(topicFor(role));
    await _messaging.unregister();
  }

  Future<void> _save(String uid, String id) async {
    try {
      await _users.addFcmToken(uid, id);
    } catch (e) {
      debugPrint('Could not save push ID: $e');
    }
  }
}
