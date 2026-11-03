import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// OpenStreetMap tiles: free, no API key or billing account (DECISIONS D50).
/// The tile server asks apps to identify themselves by package name.
TileLayer osmTileLayer() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'gh.edu.vvu.vvu_campus_safety',
);

/// The "© OpenStreetMap contributors" credit the tile licence requires.
/// Put it last in a map's children so it sits on top.
Widget osmAttribution() => RichAttributionWidget(
  showFlutterMapAttribution: false,
  attributions: [
    TextSourceAttribution(
      'OpenStreetMap contributors',
      onTap: () =>
          launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
    ),
  ],
);

/// The campus boundary outline, or nothing if fewer than 3 points are set.
PolygonLayer campusBoundaryLayer(List<GeoPoint> boundary, {Color? fill}) =>
    PolygonLayer(
      polygons: [
        if (boundary.length >= 3)
          Polygon(
            points: [for (final p in boundary) toLatLng(p)],
            color: fill,
            borderColor: AppColors.vvuBlue,
            borderStrokeWidth: 2,
          ),
      ],
    );

LatLng toLatLng(GeoPoint point) => LatLng(point.latitude, point.longitude);

/// A pin icon drawn with its tip on the marker's point.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color, this.size = 40});

  final Color color;
  final double size;

  /// Marker alignment that puts the pin's tip, not its middle, on the point.
  static const tipAlignment = Alignment.topCenter;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.location_on, color: color, size: size);
}
