import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants.dart';
import '../../../models/app_settings.dart';

/// Reads the `settings/app` document (security phone, SOS countdown, zones).
class SettingsRepository {
  SettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Live settings; defaults until the document exists.
  Stream<AppSettings> watchSettings() {
    return _firestore
        .collection(Collections.settings)
        .doc(Collections.appSettingsDoc)
        .snapshots()
        .map(
          (snap) => snap.exists
              ? AppSettings.fromMap(snap.data()!)
              : const AppSettings(),
        );
  }
}
