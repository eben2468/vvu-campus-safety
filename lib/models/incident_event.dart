import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// One entry in an incident's timeline: `incidents/{id}/events/{eventId}`.
@immutable
class IncidentEvent {
  const IncidentEvent({
    required this.id,
    required this.type,
    required this.actorId,
    this.actorName = '',
    this.text = '',
    this.timestamp,
  });

  factory IncidentEvent.fromMap(String id, Map<String, dynamic> map) {
    return IncidentEvent(
      id: id,
      type: IncidentEventType.fromValue(map['type'] as String? ?? 'note'),
      actorId: map['actorId'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final IncidentEventType type;

  /// uid of the person who acted, or `system` for Cloud Functions.
  final String actorId;
  final String actorName;
  final String text;
  final DateTime? timestamp;

  Map<String, dynamic> toMap() => {
    'type': type.value,
    'actorId': actorId,
    'actorName': actorName,
    'text': text,
    'timestamp': timestamp == null ? null : Timestamp.fromDate(timestamp!),
  };

  IncidentEvent copyWith({String? text}) => IncidentEvent(
    id: id,
    type: type,
    actorId: actorId,
    actorName: actorName,
    text: text ?? this.text,
    timestamp: timestamp,
  );
}
