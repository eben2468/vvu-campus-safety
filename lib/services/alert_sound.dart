/// Plays a short alarm tone on the web dashboard when a new SOS arrives.
/// Phones don't need it: they get a high-priority push notification.
library;

export 'alert_sound_stub.dart'
    if (dart.library.js_interop) 'alert_sound_web.dart';
