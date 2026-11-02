import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firebase Storage instance. Override in tests.
final storageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);
