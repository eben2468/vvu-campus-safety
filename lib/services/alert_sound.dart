/// Plays the siren on the web dashboard while a new SOS is waiting.
/// Phones don't need it: they get a high-priority push notification.
library;

export 'alert_sound_stub.dart'
    if (dart.library.js_interop) 'alert_sound_web.dart';
