import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';

/// Thin wrapper around Firebase Cloud Messaging and local notifications.
///
/// Push is mobile-only: the web dashboard gets new incidents from live
/// Firestore listeners instead (docs/PRD.md §4.2). Every method is a safe
/// no-op on web and never throws, because push must not break the app.
class MessagingService {
  MessagingService(this._messaging, this._local);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;

  static const _channel = AndroidNotificationChannel(
    sosAlertsChannelId,
    'SOS and incident alerts',
    description: 'New SOS alerts, reports and updates on your incidents.',
    importance: Importance.max,
  );

  bool get _supported => !kIsWeb;

  /// Sets up the alert channel and calls [onOpen] with the message data when
  /// the user taps a notification (app closed, in background or foreground).
  Future<void> init({
    required void Function(Map<String, dynamic> data) onOpen,
  }) async {
    if (!_supported) return;
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null) {
            onOpen(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          }
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // The system shows pushes in the background; in the foreground we
      // show them ourselves.
      FirebaseMessaging.onMessage.listen(_showInForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((m) => onOpen(m.data));
      final initial = await _messaging.getInitialMessage();
      if (initial != null) onOpen(initial.data);
    } catch (e) {
      debugPrint('Push setup failed: $e');
    }
  }

  /// Asks for notification permission (runtime prompt on Android 13+).
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      final settings = await _messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  /// Registers this app install with FCM. Its push address — the Firebase
  /// Installation ID (FID) — then arrives on [onRegistered], and again
  /// whenever it changes. Fails quietly on the emulator demo project, which
  /// has no real messaging sender.
  Future<void> register() => _try(_messaging.register);

  Future<void> unregister() => _try(_messaging.unregister);

  Stream<String> get onRegistered =>
      _supported ? _messaging.onRegistered : const Stream.empty();

  Future<void> subscribe(String topic) =>
      _try(() => _messaging.subscribeToTopic(topic));

  Future<void> unsubscribe(String topic) =>
      _try(() => _messaging.unsubscribeFromTopic(topic));

  Future<void> _showInForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _try(Future<void> Function() action) async {
    if (!_supported) return;
    try {
      await action();
    } catch (e) {
      debugPrint('Push call failed: $e');
    }
  }
}

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => MessagingService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
  ),
);
