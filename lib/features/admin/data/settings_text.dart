/// Text formats the settings page uses for the campus boundary and zones,
/// so they can be edited (or pasted from Google Maps) one per line.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/app_settings.dart';

/// A parse result: the value, or an error message naming the bad line.
typedef ParseResult<T> = ({T? value, String? error});

/// One `latitude, longitude` per line, e.g. `5.797, -0.126`.
String boundaryToText(List<GeoPoint> points) =>
    points.map((p) => '${p.latitude}, ${p.longitude}').join('\n');

ParseResult<List<GeoPoint>> parseBoundary(String text) {
  final points = <GeoPoint>[];
  for (final (i, line) in _lines(text)) {
    final numbers = _numbers(line.split(','));
    if (numbers == null ||
        numbers.length != 2 ||
        !_valid(numbers[0], numbers[1])) {
      return (
        value: null,
        error: 'Boundary line $i: write "latitude, longitude".',
      );
    }
    points.add(GeoPoint(numbers[0], numbers[1]));
  }
  if (points.isNotEmpty && points.length < 3) {
    return (
      value: null,
      error: 'The boundary needs at least 3 points, or none.',
    );
  }
  return (value: points, error: null);
}

/// One `name, latitude, longitude, radius in metres` per line, e.g.
/// `Hostels, 5.795, -0.124, 150`. The name may itself contain commas.
String zonesToText(List<CampusZone> zones) => zones
    .map(
      (z) =>
          '${z.name}, ${z.center.latitude}, ${z.center.longitude}, ${z.radiusM.round()}',
    )
    .join('\n');

ParseResult<List<CampusZone>> parseZones(String text) {
  final zones = <CampusZone>[];
  for (final (i, line) in _lines(text)) {
    final parts = line.split(',');
    final numbers = parts.length < 4
        ? null
        : _numbers(parts.sublist(parts.length - 3));
    final name = parts.length < 4
        ? ''
        : parts.sublist(0, parts.length - 3).join(',').trim();
    if (numbers == null ||
        name.isEmpty ||
        !_valid(numbers[0], numbers[1]) ||
        numbers[2] < 10 ||
        numbers[2] > 2000) {
      return (
        value: null,
        error:
            'Zone line $i: write "name, latitude, longitude, radius" '
            '(radius 10–2000 m).',
      );
    }
    zones.add(
      CampusZone(
        name: name,
        center: GeoPoint(numbers[0], numbers[1]),
        radiusM: numbers[2],
      ),
    );
  }
  return (value: zones, error: null);
}

/// Non-blank lines with their 1-based line numbers.
Iterable<(int, String)> _lines(String text) sync* {
  for (final (i, line) in text.split('\n').indexed) {
    if (line.trim().isNotEmpty) yield (i + 1, line);
  }
}

List<double>? _numbers(List<String> parts) {
  final numbers = parts.map((p) => double.tryParse(p.trim())).toList();
  return numbers.contains(null) ? null : numbers.cast<double>();
}

bool _valid(double lat, double lng) =>
    lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
