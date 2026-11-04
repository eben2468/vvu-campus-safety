import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/app_user.dart';
import '../../../models/chat_message.dart';
import '../../../services/api_client.dart';
import 'photo_repository.dart';

/// Per-incident chat between the reporter and security (PRD §4.6):
/// `incidents/{id}/messages`. Once a message reaches Firestore the server
/// pushes it to the other side.
class ChatRepository {
  ChatRepository(this._firestore, this._api);

  final FirebaseFirestore _firestore;
  final ApiClient _api;

  static const maxMessageLength = 2000;

  CollectionReference<Map<String, dynamic>> _messages(String incidentId) =>
      _firestore
          .collection(Collections.incidents)
          .doc(incidentId)
          .collection(Collections.messages);

  Stream<List<ChatMessage>> watchMessages(String incidentId) {
    return _messages(incidentId)
        .orderBy('timestamp')
        .limitToLast(200)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snap) => [
            for (final doc in snap.docs)
              ChatMessage.fromMap(
                doc.id,
                doc.data(),
                pendingSync: doc.metadata.hasPendingWrites,
              ),
          ],
        );
  }

  /// Sends a text and/or a photo. Text-only messages queue offline; a photo
  /// needs a connection to upload. [photo] must already be compressed.
  Future<void> send({
    required String incidentId,
    required AppUser sender,
    String text = '',
    Uint8List? photo,
  }) async {
    final doc = _messages(incidentId).doc();
    String? imageUrl;
    if (photo != null) {
      imageUrl = await _uploadPhoto(incidentId, doc.id, photo);
    }
    final write = doc.set({
      'senderId': sender.uid,
      'senderName': sender.fullName,
      'senderRole': sender.role?.name,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Runs when the message reaches Firestore, even if that's much later.
    unawaited(
      write.then<void>(
        (_) => _api.notify('notifyMessage', {
          'incidentId': incidentId,
          'messageId': doc.id,
        }),
        onError: (_) {}, // reported below
      ),
    );
    try {
      await write.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Queued offline; shown as "sending" until it reaches the server.
    } on FirebaseException {
      throw const AppException('Message not sent. Please try again.');
    }
  }

  /// Chat photos are stored beside the incident's photos.
  Future<String> _uploadPhoto(
    String incidentId,
    String messageId,
    Uint8List bytes,
  ) async {
    try {
      return await PhotoRepository.uploadOne(
        api: _api,
        incidentId: incidentId,
        fileName: 'chat_$messageId.jpg',
        bytes: bytes,
      );
    } on ApiException catch (e) {
      throw AppException(
        e.isOffline
            ? "Couldn't send the photo. Check your connection and try again."
            : "The server couldn't save the photo. Try again later.",
      );
    }
  }
}
