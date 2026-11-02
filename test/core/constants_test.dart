import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';

void main() {
  group('UserRole', () {
    test('parses known claim values', () {
      expect(UserRole.fromValue('student'), UserRole.student);
      expect(UserRole.fromValue('admin'), UserRole.admin);
    });

    test('returns null for missing or unknown claims', () {
      expect(UserRole.fromValue(null), isNull);
      expect(UserRole.fromValue('superuser'), isNull);
    });

    test('admins count as officers, officers are not members', () {
      expect(UserRole.admin.isOfficer, isTrue);
      expect(UserRole.officer.isMember, isFalse);
      expect(UserRole.staff.isMember, isTrue);
    });
  });

  test('event types store the snake_case values from ARCHITECTURE.md', () {
    expect(IncidentEventType.onScene.value, 'on_scene');
    expect(
      IncidentEventType.fromValue('false_alarm'),
      IncidentEventType.falseAlarm,
    );
  });
}
