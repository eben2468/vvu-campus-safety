import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/location_service.dart';
import '../../incidents/data/incident_repository.dart';

/// Streams the reporter's position into an active SOS
/// (docs/ARCHITECTURE.md §8): a fix on every 10 m of movement, plus a fix
/// at least every [fallbackInterval] while standing still.
class SosLocationTracker {
  SosLocationTracker({
    required this.incidentId,
    required this._location,
    required this._incidents,
  });

  final String incidentId;
  final LocationService _location;
  final IncidentRepository _incidents;

  static const fallbackInterval = Duration(seconds: 10);

  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  DateTime? _lastWrite;
  bool _stopped = false;

  void start() {
    _subscription = _location.sosPositionStream().listen(
      _record,
      onError: (Object e) => debugPrint('Location stream error: $e'),
    );
    _timer = Timer.periodic(fallbackInterval, (_) => _fallbackFix());
  }

  Future<void> stop() async {
    _stopped = true;
    _timer?.cancel();
    await _subscription?.cancel();
  }

  Future<void> _fallbackFix() async {
    final last = _lastWrite;
    if (last != null && DateTime.now().difference(last) < fallbackInterval) {
      return;
    }
    final position = await _location.currentPosition(
      timeout: const Duration(seconds: 5),
    );
    if (position != null) _record(position);
  }

  void _record(Position position) {
    if (_stopped) return;
    _lastWrite = DateTime.now();
    _incidents
        .addLocationFix(
          incidentId,
          point: GeoPoint(position.latitude, position.longitude),
          accuracy: position.accuracy,
        )
        .catchError((Object e) => debugPrint('Location write failed: $e'));
  }
}
