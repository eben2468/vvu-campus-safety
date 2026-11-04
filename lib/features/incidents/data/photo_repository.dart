import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/api_client.dart';

/// Compresses photos and uploads them through the server
/// (docs/ARCHITECTURE.md §6).
class PhotoRepository {
  PhotoRepository(this._api);

  final ApiClient _api;

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

  /// Uploads [photos] and returns their URLs, in order.
  Future<List<String>> upload({
    required String incidentId,
    required List<Uint8List> photos,
  }) async {
    try {
      return await Future.wait([
        for (final (i, bytes) in photos.indexed)
          uploadOne(
            api: _api,
            incidentId: incidentId,
            fileName: 'photo_${i + 1}.jpg',
            bytes: bytes,
          ),
      ]);
    } on ApiException catch (e) {
      throw AppException(
        e.isOffline
            ? "Couldn't upload your photos. Check your connection and try again."
            : "The server couldn't save your photos. Try again, or send the "
                  'report without them.',
      );
    }
  }

  /// Sends one compressed JPEG to the server and returns its URL.
  static Future<String> uploadOne({
    required ApiClient api,
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final result = await api.call('uploadPhoto', {
      'incidentId': incidentId,
      'fileName': fileName,
      'dataBase64': base64Encode(bytes),
    });
    return result['url'] as String;
  }
}
