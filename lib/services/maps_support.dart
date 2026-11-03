/// Whether Google Maps can be shown. Always true on phones; on the web it
/// needs the Maps JavaScript API script in `web/index.html`, which is only
/// added once there is a Maps key (docs/SETUP.md §4).
library;

export 'maps_support_stub.dart'
    if (dart.library.js_interop) 'maps_support_web.dart';
