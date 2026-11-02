/// Saves a text file to the user's Downloads (web dashboard only).
library;

export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';
