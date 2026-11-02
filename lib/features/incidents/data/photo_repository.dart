import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';

/// Compresses and uploads incident photos to Storage at
/// `incidents/{incidentId}/photo_N.jpg` (docs/ARCHITECTURE.md §6).
class PhotoRepository {
  PhotoRepository(this._storage);

  final FirebaseStorage _storage;

  /// Re-encodes a photo as JPEG, lowering quality until it fits in
  /// [maxPhotoBytes] (≤ 1 MB, D5).
  static Future<Uint8List> compress(Uint8List original) async {
    for (final quality in [80, 65, 50, 35]) {
      final bytes = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1600,
        minHeight: 1600,
        quality: quality,
      );
      if (bytes.length <= maxPhotoBytes) return bytes;
    }
    throw const AppException('That photo is too large. Try a different one.');
  }

  /// Uploads [photos] and returns their download URLs, in order.
  ///
  /// `reporterId` is stored as custom metadata so `storage.rules` can let
  /// the reporter (and officers) read the files without a Firestore lookup.
  Future<List<String>> upload({
    required String incidentId,
    required String reporterId,
    required List<Uint8List> photos,
  }) async {
    try {
      return await Future.wait([
        for (final (i, bytes) in photos.indexed)
          _uploadOne(
            _storage.ref(
              '$storageIncidentsFolder/$incidentId/photo_${i + 1}.jpg',
            ),
            bytes,
            reporterId,
          ),
      ]);
    } on FirebaseException {
      throw const AppException(
        "Couldn't upload your photos. Check your connection and try again.",
      );
    }
  }

  Future<String> _uploadOne(
    Reference ref,
    Uint8List bytes,
    String reporterId,
  ) async {
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'reporterId': reporterId},
      ),
    );
    return ref.getDownloadURL();
  }
}
