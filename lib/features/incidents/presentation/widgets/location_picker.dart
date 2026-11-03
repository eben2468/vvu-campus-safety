import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/osm_layers.dart';

/// A map with a pin the user can move by tapping, to mark where an
/// incident happened.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Null until the GPS fix arrives or the user taps the map.
  final GeoPoint? value;
  final ValueChanged<GeoPoint> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _controller = MapController();
  bool _ready = false;

  static const _campus = LatLng(campusCenterLat, campusCenterLng);

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the first GPS fix; after that the user is in control.
    final value = widget.value;
    if (_ready && oldWidget.value == null && value != null) {
      _controller.move(toLatLng(value), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(LatLng position) =>
      widget.onChanged(GeoPoint(position.latitude, position.longitude));

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where did it happen?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        const Text('Tap the map to move the pin to the right spot.'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: value == null ? _campus : toLatLng(value),
                initialZoom: 16,
                onMapReady: () => _ready = true,
                onTap: (_, point) => _set(point),
              ),
              children: [
                osmTileLayer(),
                MarkerLayer(
                  markers: [
                    if (value != null)
                      Marker(
                        point: toLatLng(value),
                        width: 40,
                        height: 40,
                        alignment: MapPin.tipAlignment,
                        child: const MapPin(color: AppColors.sosRed),
                      ),
                  ],
                ),
                osmAttribution(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
