import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme.dart';
import '../../../../core/widgets/osm_layers.dart';

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
  final _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(IncidentMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final point = widget.point;
    if (_ready && point != null && point != oldWidget.point) {
      _controller.move(toLatLng(point), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: toLatLng(point),
        initialZoom: 17,
        onMapReady: () => _ready = true,
      ),
      children: [
        osmTileLayer(),
        MarkerLayer(
          markers: [
            Marker(
              point: toLatLng(point),
              width: 40,
              height: 40,
              alignment: MapPin.tipAlignment,
              child: Tooltip(
                message: widget.label ?? 'Reporter',
                child: const MapPin(color: AppColors.sosRed),
              ),
            ),
          ],
        ),
        osmAttribution(),
      ],
    );
  }
}
