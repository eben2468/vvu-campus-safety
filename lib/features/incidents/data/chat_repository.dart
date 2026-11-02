import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/app_user.dart';
import '../../../models/chat_message.dart';

/// Per-incident chat between the reporter and security (PRD §4.6):
/// `incidents/{id}/messages`. The `onMessageCreated` function pushes each
/// message to the other side.
class ChatRepository {
  ChatRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
    required String reporterId,
    required AppUser sender,
    String text = '',
    Uint8List? photo,
  }) async {
    final doc = _messages(incidentId).doc();
    String? imageUrl;
    if (photo != null) {
      imageUrl = await _uploadPhoto(incidentId, doc.id, reporterId, photo);
    }
    final write = doc.set({
      'senderId': sender.uid,
      'senderName': sender.fullName,
      'senderRole': sender.role?.name,
      'text': text.trim(),
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
    try {
      await write.timeout(const Duration(seconds: 6));
    } on TimeoutException {
      // Queued offline; shown as "sending" until it reaches the server.
    } on FirebaseException {
      throw const AppException('Message not sent. Please try again.');
    }
  }

  /// Chat photos sit beside the incident's photos. They carry the
  /// incident's reporter as `reporterId` so both sides can open them.
  Future<String> _uploadPhoto(
    String incidentId,
    String messageId,
    String reporterId,
    Uint8List bytes,
  ) async {
    final ref = _storage.ref(
      '$storageIncidentsFolder/$incidentId/chat_$messageId.jpg',
    );
    try {
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'reporterId': reporterId},
        ),
      );
      return await ref.getDownloadURL();
    } on FirebaseException {
      throw const AppException(
        "Couldn't send the photo. Check your connection and try again.",
      );
    }
  }
}
