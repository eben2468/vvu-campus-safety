import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/widgets/maps_unavailable.dart';
import '../../../../services/maps_support.dart';

/// A map centred on an incident's position, following it as it moves.
class IncidentMap extends StatefulWidget {
  const IncidentMap({
    super.key,
    required this.point,
    this.label,
    this.emptyMessage =
        'Location not available yet. Call the reporter to find them.',
  });

  /// Null shows a "no location" placeholder instead of a map.
  final GeoPoint? point;
  final String? label;

  /// Shown instead of the map when [point] is null.
  final String emptyMessage;

  @override
  State<IncidentMap> createState() => _IncidentMapState();
}

class _IncidentMapState extends State<IncidentMap> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(IncidentMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final point = widget.point;
    if (point != null && point != oldWidget.point) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_latLng(point)));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.point;
    if (point == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.emptyMessage, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    if (!mapsAvailable) return const MapsUnavailable();
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _latLng(point), zoom: 17),
      onMapCreated: (controller) => _controller = controller,
      markers: {
        Marker(
          markerId: const MarkerId('reporter'),
          position: _latLng(point),
          infoWindow: InfoWindow(title: widget.label ?? 'Reporter'),
        ),
      },
      myLocationButtonEnabled: false,
    );
  }

  static LatLng _latLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);
}
