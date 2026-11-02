/// Input normalisers and display formatters.
library;

import 'package:intl/intl.dart';

/// Converts a Ghana phone number to E.164 (`+233` + 9 digits).
///
/// Accepts `024 123 4567`, `0241234567`, `241234567`, `233241234567` and
/// `+233241234567`. Returns null if the input is not a Ghana number.
String? normalizeGhanaPhone(String input) {
  final compact = input.replaceAll(RegExp(r'[\s\-()]'), '');
  final match = RegExp(r'^(?:\+233|00233|233|0)?(\d{9})$').firstMatch(compact);
  return match == null ? null : '+233${match.group(1)}';
}

/// Uppercases a VVU ID number and removes spaces, e.g. `223it 0100946`
/// becomes `223IT0100946`. Must match `normalizeIdNumber` in functions/src/roster.ts.
String normalizeIdNumber(String input) =>
    input.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Times are shown in Africa/Accra, which is UTC+0 all year (no DST).
String formatTime(DateTime time) => DateFormat('HH:mm').format(time.toUtc());

String formatDateTime(DateTime time) =>
    DateFormat('d MMM yyyy, HH:mm').format(time.toUtc());

/// "just now", "5 min ago", "2 h ago", or the date for anything older.
String timeAgo(DateTime time, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(time);
  if (elapsed.inMinutes < 1) return 'just now';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours} h ago';
  return formatDateTime(time);
}
