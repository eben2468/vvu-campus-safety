import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import 'incident_status.dart';

/// An SOS or incident report: the `incidents/{id}` document.
@immutable
class Incident {
  const Incident({
    required this.id,
    required this.kind,
    required this.status,
    required this.reporterId,
    this.category = sosCategory,
    this.description = '',
    this.reporterName = '',
    this.reporterPhone = '',
    this.location,
    this.geohash,
    this.lastLocation,
    this.locationLabel,
    this.mediaUrls = const [],
    this.assignedTo = const [],
    this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.responseSeconds,
    this.active = true,
    this.cancelledByReporter = false,
    this.pendingSync = false,
  });

  /// [pendingSync] comes from the snapshot metadata, not the document.
  factory Incident.fromMap(
    String id,
    Map<String, dynamic> map, {
    bool pendingSync = false,
  }) {
    return Incident(
      id: id,
      kind: IncidentKind.fromValue(map['kind'] as String? ?? 'report'),
      status: IncidentStatus.fromValue(map['status'] as String? ?? 'new'),
      reporterId: map['reporterId'] as String? ?? '',
      category: map['category'] as String? ?? sosCategory,
      description: map['description'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      reporterPhone: map['reporterPhone'] as String? ?? '',
      location: map['location'] as GeoPoint?,
      geohash: map['geohash'] as String?,
      lastLocation: map['lastLocation'] as GeoPoint?,
      locationLabel: map['locationLabel'] as String?,
      mediaUrls: List<String>.from(map['mediaUrls'] as List? ?? const []),
      assignedTo: List<String>.from(map['assignedTo'] as List? ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      acknowledgedAt: (map['acknowledgedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      responseSeconds: (map['responseSeconds'] as num?)?.toInt(),
      active: map['active'] as bool? ?? true,
      cancelledByReporter: map['cancelledByReporter'] as bool? ?? false,
      pendingSync: pendingSync,
    );
  }

  final String id;
  final IncidentKind kind;
  final IncidentStatus status;
  final String reporterId;
  final String category;
  final String description;
  final String reporterName;
  final String reporterPhone;

  /// Where the incident was raised. Null if the phone had no location fix.
  final GeoPoint? location;
  final String? geohash;

  /// Latest position while an SOS is active.
  final GeoPoint? lastLocation;
  final String? locationLabel;
  final List<String> mediaUrls;
  final List<String> assignedTo;
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final int? responseSeconds;
  final bool active;
  final bool cancelledByReporter;

  /// True while the document is only in the local cache (e.g. offline).
  final bool pendingSync;

  bool get isSos => kind == IncidentKind.sos;

  /// Best known position: live position during an SOS, else the original.
  GeoPoint? get currentLocation => lastLocation ?? location;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'category': category,
    'description': description,
    'status': status.value,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'reporterPhone': reporterPhone,
    'location': location,
    'geohash': geohash,
    'lastLocation': lastLocation,
    'locationLabel': locationLabel,
    'mediaUrls': mediaUrls,
    'assignedTo': assignedTo,
    'createdAt': _timestamp(createdAt),
    'acknowledgedAt': _timestamp(acknowledgedAt),
    'resolvedAt': _timestamp(resolvedAt),
    'responseSeconds': responseSeconds,
    'active': active,
    'cancelledByReporter': cancelledByReporter,
  };

  Incident copyWith({
    IncidentStatus? status,
    GeoPoint? lastLocation,
    String? locationLabel,
    List<String>? mediaUrls,
    List<String>? assignedTo,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    int? responseSeconds,
    bool? active,
    bool? cancelledByReporter,
    bool? pendingSync,
  }) {
    return Incident(
      id: id,
      kind: kind,
      status: status ?? this.status,
      reporterId: reporterId,
      category: category,
      description: description,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      location: location,
      geohash: geohash,
      lastLocation: lastLocation ?? this.lastLocation,
      locationLabel: locationLabel ?? this.locationLabel,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      responseSeconds: responseSeconds ?? this.responseSeconds,
      active: active ?? this.active,
      cancelledByReporter: cancelledByReporter ?? this.cancelledByReporter,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  static Timestamp? _timestamp(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}
