import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env.dart';
import 'firebase_options.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (useEmulator) {
    await _connectToEmulators();
  }
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const App(),
    ),
  );
}

/// Points every Firebase SDK at the local Emulator Suite.
/// Ports match `firebase.json`.
Future<void> _connectToEmulators() async {
  // 10.0.2.2 is the Android emulator's alias for the PC.
  final host = emulatorHostOverride.isNotEmpty
      ? emulatorHostOverride
      : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      ? '10.0.2.2'
      : 'localhost';

  // The SDKs would silently rewrite 127.0.0.1 to 10.0.2.2 on Android, which
  // breaks a physical phone using `adb reverse`; the host above is already
  // right for each case, so turn that mapping off.
  await FirebaseAuth.instance.useAuthEmulator(
    host,
    9099,
    automaticHostMapping: false,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    host,
    8080,
    automaticHostMapping: false,
  );
  FirebaseFunctions.instanceFor(region: functionsRegion)
      .useFunctionsEmulator(host, 5001, automaticHostMapping: false);
  await FirebaseStorage.instance.useStorageEmulator(
    host,
    9199,
    automaticHostMapping: false,
  );
  debugPrint('Using Firebase emulators on $host');
}
