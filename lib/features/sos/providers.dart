import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../models/app_settings.dart';
import '../../models/incident.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../auth/providers.dart';
import '../incidents/providers.dart';
import 'data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(firestoreProvider));
});

/// `settings/app`, live.
final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

/// The signed-in member's open SOS, or null.
final myActiveSosProvider = StreamProvider<Incident?>((ref) {
  final uid = ref.watch(sessionProvider.select((s) => s.profile?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(incidentRepositoryProvider).watchMyActiveSos(uid);
});

/// Current location permission state; invalidate after asking.
final locationAccessProvider = FutureProvider<LocationAccess>((ref) {
  return ref.watch(locationServiceProvider).access();
});

final sosControllerProvider = Provider<SosController>(SosController.new);

/// Sends an SOS. Location is fetched while the countdown runs, and the SOS
/// is never held back for long waiting for it.
class SosController {
  SosController(this._ref);

  final Ref _ref;

  /// Longest extra wait for a GPS fix after the countdown ends.
  static const maxLocationWait = Duration(seconds: 3);

  /// Starts a location fix; pass the result to [send].
  Future<Position?> startLocationFix() => _ref
      .read(locationServiceProvider)
      .currentPosition(timeout: const Duration(seconds: 6));

  Future<void> send(Future<Position?> locationFix) async {
    final reporter = _ref.read(sessionProvider).profile;
    if (reporter == null) {
      throw const AppException(
        'Your profile is still loading. Call security now.',
      );
    }
    if (_ref.read(myActiveSosProvider).value != null) return; // one at a time

    final position = await locationFix.timeout(
      maxLocationWait,
      onTimeout: () => null,
    );
    final point = position == null
        ? null
        : GeoPoint(position.latitude, position.longitude);
    final settings =
        _ref.read(appSettingsProvider).value ?? const AppSettings();

    await _ref
        .read(incidentRepositoryProvider)
        .createSos(
          reporter: reporter,
          location: point,
          locationLabel: point == null ? null : settings.zoneNameFor(point),
        );
  }
}
