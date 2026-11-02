import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/utils/geo.dart';

/// A named campus area, e.g. "Hostels", used to label incident locations.
@immutable
class CampusZone {
  const CampusZone({
    required this.name,
    required this.center,
    required this.radiusM,
  });

  factory CampusZone.fromMap(Map<String, dynamic> map) => CampusZone(
    name: map['name'] as String? ?? '',
    center: map['center'] as GeoPoint? ?? const GeoPoint(0, 0),
    radiusM: (map['radiusM'] as num?)?.toDouble() ?? 0,
  );

  final String name;
  final GeoPoint center;
  final double radiusM;

  Map<String, dynamic> toMap() => {
    'name': name,
    'center': center,
    'radiusM': radiusM,
  };

  bool contains(GeoPoint point) =>
      distanceMeters(
        center.latitude,
        center.longitude,
        point.latitude,
        point.longitude,
      ) <=
      radiusM;
}

/// The single `settings/app` document, edited by admins.
@immutable
class AppSettings {
  const AppSettings({
    this.categories = defaultCategories,
    this.securityPhone = '',
    this.sosCountdownSec = defaultSosCountdownSec,
    this.campusBoundary = const [],
    this.zones = const [],
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
    categories: List<String>.from(
      map['categories'] as List? ?? defaultCategories,
    ),
    securityPhone: map['securityPhone'] as String? ?? '',
    sosCountdownSec:
        (map['sosCountdownSec'] as num?)?.toInt() ?? defaultSosCountdownSec,
    campusBoundary: List<GeoPoint>.from(
      map['campusBoundary'] as List? ?? const [],
    ),
    zones: [
      for (final zone in map['zones'] as List? ?? const [])
        CampusZone.fromMap(Map<String, dynamic>.from(zone as Map)),
    ],
  );

  final List<String> categories;

  /// Security Office emergency number in E.164; empty if not set yet.
  final String securityPhone;
  final int sosCountdownSec;
  final List<GeoPoint> campusBoundary;
  final List<CampusZone> zones;

  Map<String, dynamic> toMap() => {
    'categories': categories,
    'securityPhone': securityPhone,
    'sosCountdownSec': sosCountdownSec,
    'campusBoundary': campusBoundary,
    'zones': [for (final zone in zones) zone.toMap()],
  };

  AppSettings copyWith({
    List<String>? categories,
    String? securityPhone,
    int? sosCountdownSec,
    List<GeoPoint>? campusBoundary,
    List<CampusZone>? zones,
  }) => AppSettings(
    categories: categories ?? this.categories,
    securityPhone: securityPhone ?? this.securityPhone,
    sosCountdownSec: sosCountdownSec ?? this.sosCountdownSec,
    campusBoundary: campusBoundary ?? this.campusBoundary,
    zones: zones ?? this.zones,
  );

  /// Name of the first zone containing [point], or null.
  String? zoneNameFor(GeoPoint point) {
    for (final zone in zones) {
      if (zone.contains(point)) return zone.name;
    }
    return null;
  }
}
