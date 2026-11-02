/// Build-time environment flags, set with `--dart-define`.
library;

/// True when run with `--dart-define=USE_EMULATOR=true`.
const useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Optional host running the Emulator Suite. Leave empty to use the default
/// (`10.0.2.2` on the Android emulator, `localhost` elsewhere). For a physical
/// phone pass your PC's LAN IP: `--dart-define=EMULATOR_HOST=192.168.x.x`.
const emulatorHostOverride = String.fromEnvironment('EMULATOR_HOST');

/// Region the Cloud Functions are deployed to (see functions/src/index.ts).
const functionsRegion = 'europe-west1';
