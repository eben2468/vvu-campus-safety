import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Builds the file in the browser and clicks a hidden download link.
void downloadTextFile(
  String fileName,
  String text, {
  String mimeType = 'text/csv',
}) {
  // A byte-order mark makes Excel read the file as UTF-8 (names like "Ɔ").
  final bytes = utf8.encode('﻿$text');
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  link.click();
  web.URL.revokeObjectURL(url);
}
