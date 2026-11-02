import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../models/app_settings.dart';
import '../../../../../models/incident.dart';

/// The campus with a marker for every open incident: red for SOS, blue for
/// reports. Incidents without a location are only in the list.
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
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(campusCenterLat, campusCenterLng),
        zoom: 16,
      ),
      markers: {
        for (final incident in incidents)
          if (incident.currentLocation case final point?)
            Marker(
              markerId: MarkerId(incident.id),
              position: LatLng(point.latitude, point.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                incident.isSos
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueAzure,
              ),
              // SOS markers sit on top of reports.
              zIndexInt: incident.isSos ? 1 : 0,
              infoWindow: InfoWindow(
                title: incident.isSos
                    ? 'SOS — ${incident.reporterName}'
                    : '${incident.category} — ${incident.reporterName}',
                snippet: incident.status.label,
                onTap: () => onOpen(incident),
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
            fillColor: AppColors.vvuBlue.withValues(alpha: 0.05),
          ),
      },
      myLocationButtonEnabled: false,
    );
  }
}
