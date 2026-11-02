/// Small geo helpers with no Firebase dependency, so they are easy to test.
library;

import 'dart:math' as math;

const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Standard geohash of a point (stored on incidents for future geo queries).
String geohash(double latitude, double longitude, {int precision = 9}) {
  var latRange = [-90.0, 90.0];
  var lngRange = [-180.0, 180.0];
  final hash = StringBuffer();
  var bit = 0;
  var ch = 0;
  var evenBit = true; // even bits encode longitude

  while (hash.length < precision) {
    final range = evenBit ? lngRange : latRange;
    final value = evenBit ? longitude : latitude;
    final mid = (range[0] + range[1]) / 2;
    if (value >= mid) {
      ch = (ch << 1) | 1;
      range[0] = mid;
    } else {
      ch = ch << 1;
      range[1] = mid;
    }
    evenBit = !evenBit;
    if (++bit == 5) {
      hash.write(_base32[ch]);
      bit = 0;
      ch = 0;
    }
  }
  return hash.toString();
}

/// Great-circle distance in metres (haversine formula).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(a));
}
