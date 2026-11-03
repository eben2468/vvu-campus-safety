import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// True once the Maps JavaScript API has loaded (`window.google.maps`).
/// Without it, building a map throws and the whole page turns red.
bool get mapsAvailable {
  final google = globalContext['google'];
  return google.isA<JSObject>() && (google as JSObject).has('maps');
}
