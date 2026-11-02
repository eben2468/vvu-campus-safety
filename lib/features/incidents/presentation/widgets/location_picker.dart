import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants.dart';

/// A map with a pin the user can move by tapping or dragging, to mark
/// where an incident happened.
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
  GoogleMapController? _controller;

  static const _campus = LatLng(campusCenterLat, campusCenterLng);

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow the first GPS fix; after that the user is in control.
    final value = widget.value;
    if (oldWidget.value == null && value != null) {
      _controller?.animateCamera(CameraUpdate.newLatLng(_latLng(value)));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
        const Text('Tap the map or drag the pin to the right spot.'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: value == null ? _campus : _latLng(value),
                zoom: 16,
              ),
              onMapCreated: (controller) => _controller = controller,
              onTap: _set,
              markers: {
                if (value != null)
                  Marker(
                    markerId: const MarkerId('incident'),
                    position: _latLng(value),
                    draggable: true,
                    onDragEnd: _set,
                  ),
              },
              myLocationButtonEnabled: false,
            ),
          ),
        ),
      ],
    );
  }

  static LatLng _latLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);
}
