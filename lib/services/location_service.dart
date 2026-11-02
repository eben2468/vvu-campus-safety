import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Whether the app can read the phone's location.
enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// Thin wrapper around geolocator: permission checks, current position and
/// the SOS position stream (docs/ARCHITECTURE.md §8).
class LocationService {
  Future<LocationAccess> access() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _toAccess(await Geolocator.checkPermission());
  }

  /// Asks for permission if it hasn't been refused for good.
  Future<LocationAccess> requestAccess() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _toAccess(permission);
  }

  /// Best available fix within [timeout], else the last known position,
  /// else null. Never throws — an SOS must not fail for lack of GPS.
  Future<Position?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      if (await access() != LocationAccess.granted) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Position updates every 10 m of movement. On Android this runs as a
  /// foreground service with a visible notification, so tracking continues
  /// with the screen off.
  Stream<Position> sosPositionStream() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'SOS active',
            notificationText: 'Sharing your location with campus security until your alert is closed.',
            notificationChannelName: 'Active SOS',
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      );
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  static LocationAccess _toAccess(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
