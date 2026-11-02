import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/utils/formatters.dart';
import 'package:vvu_campus_safety/core/utils/geo.dart';

void main() {
  test('geohash matches known values', () {
    // Reference values from the standard geohash algorithm.
    expect(geohash(57.64911, 10.40744, precision: 11), 'u4pruydqqvj');
    expect(geohash(0, 0, precision: 5), 's0000');
  });

  test('distanceMeters is close to known distances', () {
    // 0.001° of latitude is about 111 m.
    expect(distanceMeters(5.793, -0.122, 5.794, -0.122), closeTo(111, 1));
    expect(distanceMeters(5.793, -0.122, 5.793, -0.122), 0);
  });

  group('time formatting (Africa/Accra = UTC)', () {
    test('formats in UTC', () {
      final time = DateTime.utc(2026, 11, 2, 21, 5);
      expect(formatTime(time), '21:05');
      expect(formatDateTime(time), '2 Nov 2026, 21:05');
    });

    test('timeAgo', () {
      final now = DateTime.utc(2026, 11, 2, 12);
      expect(
        timeAgo(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
      expect(
        timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3 h ago',
      );
    });
  });
}
