import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/widgets/osm_layers.dart';
import '../../../../../models/app_settings.dart';
import '../../../data/analytics.dart';

/// The campus with a circle for each grid square that had incidents:
/// larger and redder for more, with its count written on it.
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
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(campusCenterLat, campusCenterLng),
        initialZoom: 16,
      ),
      children: [
        osmTileLayer(),
        campusBoundaryLayer(settings.campusBoundary),
        CircleLayer(
          circles: [
            // Quietest first so the busiest squares are drawn on top.
            for (final cell in cells.reversed)
              CircleMarker(
                point: LatLng(cell.latitude, cell.longitude),
                // Area grows with the count, so radius grows with its root.
                radius:
                    cellMeters / 2 * (0.6 + 0.8 * math.sqrt(cell.count / most)),
                useRadiusInMeter: true,
                color: _heat(cell.count / most).withValues(alpha: 0.55),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final cell in cells)
              Marker(
                point: LatLng(cell.latitude, cell.longitude),
                child: Tooltip(
                  message:
                      '${cell.count} incident${cell.count == 1 ? '' : 's'} '
                      'here',
                  child: Center(
                    child: Text(
                      '${cell.count}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        osmAttribution(),
      ],
    );
  }

  /// Yellow for few incidents through orange to red for the busiest square.
  static Color _heat(double share) =>
      Color.lerp(const Color(0xFFFFD54F), AppColors.sosRed, share.clamp(0, 1))!;
}
