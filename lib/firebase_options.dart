// TEMPORARY emulator-only options for the `demo-vvu-campus-safety` project.
//
// The Firebase Emulator Suite accepts any "demo-" project without a real
// Firebase project or login, so the app can run locally before the real
// project exists. These values do NOT reach any real Firebase service.
//
// Replace this file by running:
//   flutterfire configure --project=vvu-campus-safety --platforms=android,web
// After that this file is generated — do not edit it by hand.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-vvu-campus-safety',
    authDomain: 'demo-vvu-campus-safety.firebaseapp.com',
    storageBucket: 'demo-vvu-campus-safety.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'demo-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'demo-vvu-campus-safety',
    storageBucket: 'demo-vvu-campus-safety.appspot.com',
  );
}
