/// Build-time environment flags, set with `--dart-define`.
library;

import 'package:flutter/foundation.dart';

/// True when run with `--dart-define=USE_EMULATOR=true`.
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Optional host running the Emulator Suite. Leave empty to use the default
/// (`10.0.2.2` on the Android emulator, `localhost` elsewhere). For a physical
/// phone pass your PC's LAN IP: `--dart-define=EMULATOR_HOST=192.168.x.x`.
const emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// The deployed API, e.g. `https://vvu-safety.vercel.app/api`. Required for
/// release builds: `--dart-define=API_URL=...` (docs/SETUP.md §8).
const apiUrlOverride = String.fromEnvironment('API_URL');

/// Where the Firebase emulators and the local API server run.
String get emulatorHost {
  if (emulatorHostOverride.isNotEmpty) return emulatorHostOverride;
  // 10.0.2.2 is the Android emulator's alias for the PC.
  final androidEmulator =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  return androidEmulator ? '10.0.2.2' : 'localhost';
}

/// The API's base URL. In emulator mode, `npm run api:dev` on port 3000.
String get apiBaseUrl =>
    useEmulator ? 'http://$emulatorHost:3000/api' : apiUrlOverride;
