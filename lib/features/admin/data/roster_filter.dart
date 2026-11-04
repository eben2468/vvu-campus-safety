import '../../../models/roster_entry.dart';

/// Which IDs the roster table lists. A blocked ID counts only as blocked,
/// even if someone registered with it earlier.
enum RosterFilter {
  all('All'),
  notRegistered('Not registered'),
  registered('Registered'),
  blocked('Blocked');

  const RosterFilter(this.label);

  final String label;

  bool includes(RosterEntry entry) => switch (this) {
    RosterFilter.all => true,
    RosterFilter.notRegistered => entry.active && !entry.isRegistered,
    RosterFilter.registered => entry.active && entry.isRegistered,
    RosterFilter.blocked => !entry.active,
  };
}

/// Whether [entry]'s ID, name, department or type contains [query].
bool rosterEntryMatches(RosterEntry entry, String query) {
  final text = query.trim().toLowerCase();
  if (text.isEmpty) return true;
  return [
    entry.idNumber,
    entry.fullName,
    entry.department,
    entry.type,
  ].any((field) => field.toLowerCase().contains(text));
}
