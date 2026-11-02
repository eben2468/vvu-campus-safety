/// Input normalisers shared by forms and repositories.
library;

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
