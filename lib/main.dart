import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

/// Points Firebase at the local Emulator Suite. Ports match `firebase.json`.
Future<void> _connectToEmulators() async {
  final host = emulatorHost;
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
  debugPrint('Using Firebase emulators on $host');
}
