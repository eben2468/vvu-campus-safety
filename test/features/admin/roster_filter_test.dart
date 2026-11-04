import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/admin/data/roster_filter.dart';
import 'package:vvu_campus_safety/models/roster_entry.dart';

void main() {
  const open = RosterEntry(
    idNumber: '225IT0100101',
    fullName: 'Ama Owusu',
    type: 'student',
    department: 'Nursing',
  );
  const registered = RosterEntry(
    idNumber: '225IT0100102',
    fullName: 'Kofi Boateng',
    type: 'staff',
    claimedBy: 'uid-1',
  );
  const blocked = RosterEntry(
    idNumber: '225IT0100103',
    fullName: 'Yaw Darko',
    type: 'student',
    active: false,
    claimedBy: 'uid-2',
  );
  const entries = [open, registered, blocked];

  List<RosterEntry> matching(RosterFilter filter) =>
      entries.where(filter.includes).toList();

  test('each ID falls under one status', () {
    expect(matching(RosterFilter.all), entries);
    expect(matching(RosterFilter.notRegistered), [open]);
    expect(matching(RosterFilter.registered), [registered]);
    expect(matching(RosterFilter.blocked), [blocked]);
  });

  test('search covers ID, name, department and type, ignoring case', () {
    expect(rosterEntryMatches(open, '225it'), isTrue);
    expect(rosterEntryMatches(open, ' ama '), isTrue);
    expect(rosterEntryMatches(open, 'nursing'), isTrue);
    expect(rosterEntryMatches(registered, 'STAFF'), isTrue);
    expect(rosterEntryMatches(open, 'boateng'), isFalse);
    expect(rosterEntryMatches(open, ''), isTrue);
  });

  test('fromMap reads a stored entry and fills in defaults', () {
    final entry = RosterEntry.fromMap('225IT0100101', {
      'fullName': 'Ama Owusu',
      'type': 'student',
    });
    expect(entry.idNumber, '225IT0100101');
    expect(entry.department, '');
    expect(entry.active, isTrue);
    expect(entry.isRegistered, isFalse);
  });
}
