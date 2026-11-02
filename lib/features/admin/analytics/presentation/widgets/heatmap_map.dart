import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../models/app_settings.dart';
import '../../../data/analytics.dart';

/// The campus with a circle for each grid square that had incidents:
/// larger and redder for more. Tap a circle to see its count.
class HeatmapMap extends StatelessWidget {
  const HeatmapMap({
    super.key,
    required this.cells,
    required this.settings,
    this.cellMeters = 50,
  });

  final List<HeatCell> cells;
  final AppSettings settings;
  final double cellMeters;

  @override
  Widget build(BuildContext context) {
    final most = cells.isEmpty ? 1 : cells.first.count; // sorted, busiest first
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(campusCenterLat, campusCenterLng),
        zoom: 16,
      ),
      circles: {
        for (final (i, cell) in cells.indexed)
          Circle(
            circleId: CircleId('cell$i'),
            center: LatLng(cell.latitude, cell.longitude),
            // Area grows with the count, so radius grows with its root.
            radius: cellMeters / 2 * (0.6 + 0.8 * math.sqrt(cell.count / most)),
            fillColor: _heat(cell.count / most).withValues(alpha: 0.55),
            strokeWidth: 0,
            consumeTapEvents: true,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${cell.count} incident${cell.count == 1 ? '' : 's'} here.',
                ),
              ),
            ),
          ),
      },
      polygons: {
        if (settings.campusBoundary.length >= 3)
          Polygon(
            polygonId: const PolygonId('campus'),
            points: [
              for (final p in settings.campusBoundary)
                LatLng(p.latitude, p.longitude),
            ],
            strokeColor: AppColors.vvuBlue,
            strokeWidth: 2,
            fillColor: Colors.transparent,
          ),
      },
      myLocationButtonEnabled: false,
    );
  }

  /// Yellow for few incidents through orange to red for the busiest square.
  static Color _heat(double share) =>
      Color.lerp(const Color(0xFFFFD54F), AppColors.sosRed, share.clamp(0, 1))!;
}
