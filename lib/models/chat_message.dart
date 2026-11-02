import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// One chat message on an incident: `incidents/{id}/messages/{messageId}`.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    this.text = '',
    this.imageUrl,
    this.timestamp,
    this.pendingSync = false,
  });

  factory ChatMessage.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool pendingSync = false,
  }) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      senderRole: UserRole.fromValue(map['senderRole'] as String?),
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
      pendingSync: pendingSync,
    );
  }

  final String id;
  final String senderId;
  final String senderName;
  final UserRole? senderRole;
  final String text;
  final String? imageUrl;
  final DateTime? timestamp;

  /// True until the server has the message (e.g. offline).
  final bool pendingSync;

  bool get fromSecurity => senderRole?.isOfficer ?? false;

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole?.name,
    'text': text,
    'imageUrl': imageUrl,
    'timestamp': timestamp == null ? null : Timestamp.fromDate(timestamp!),
  };

  ChatMessage copyWith({String? text, String? imageUrl}) => ChatMessage(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderRole: senderRole,
    text: text ?? this.text,
    imageUrl: imageUrl ?? this.imageUrl,
    timestamp: timestamp,
    pendingSync: pendingSync,
  );
}
