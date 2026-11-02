import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/env.dart';

/// Cloud Functions in [functionsRegion] — the same instance `main.dart`
/// points at the emulator. Override in tests.
final functionsProvider = Provider<FirebaseFunctions>(
  (ref) => FirebaseFunctions.instanceFor(region: functionsRegion),
);
