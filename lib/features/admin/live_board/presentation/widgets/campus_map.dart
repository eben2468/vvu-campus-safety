import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../core/widgets/osm_layers.dart';
import '../../../../../models/app_settings.dart';
import '../../../../../models/incident.dart';

/// The campus with a pin for every open incident: red for SOS, blue for
/// reports. Hover a pin for who and what; click it to open the incident.
/// Incidents without a location are only in the list.
class CampusMap extends StatelessWidget {
  const CampusMap({
    super.key,
    required this.incidents,
    required this.settings,
    required this.onOpen,
  });

  final List<Incident> incidents;
  final AppSettings settings;
  final void Function(Incident incident) onOpen;

  @override
  Widget build(BuildContext context) {
    // Reports first so SOS pins are drawn on top.
    final located = [
      for (final incident in incidents)
        if (incident.currentLocation != null) incident,
    ]..sort((a, b) => (a.isSos ? 1 : 0).compareTo(b.isSos ? 1 : 0));

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(campusCenterLat, campusCenterLng),
        initialZoom: 16,
      ),
      children: [
        osmTileLayer(),
        campusBoundaryLayer(
          settings.campusBoundary,
          fill: AppColors.vvuBlue.withValues(alpha: 0.05),
        ),
        MarkerLayer(
          markers: [
            for (final incident in located)
              Marker(
                point: toLatLng(incident.currentLocation!),
                width: 40,
                height: 40,
                alignment: MapPin.tipAlignment,
                child: Tooltip(
                  message: incident.isSos
                      ? 'SOS — ${incident.reporterName} '
                            '(${incident.status.label})'
                      : '${incident.category} — ${incident.reporterName} '
                            '(${incident.status.label})',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onOpen(incident),
                      child: MapPin(
                        color: incident.isSos
                            ? AppColors.sosRed
                            : AppColors.vvuBlue,
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
}
