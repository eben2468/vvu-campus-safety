import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/models/app_user.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 2, 9, 30);
  final map = <String, dynamic>{
    'fullName': 'Kwame Mensah',
    'email': 'kwame@example.com',
    'phone': '+233241234567',
    'idNumber': '223IT0100001',
    'role': 'student',
    'verified': true,
    'onDuty': false,
    'fcmTokens': ['token-1'],
    'falseAlarmCount': 2,
    'deactivated': false,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  test('reads a users document', () {
    final user = AppUser.fromMap('uid-1', map);
    expect(user.uid, 'uid-1');
    expect(user.role, UserRole.student);
    expect(user.fcmTokens, ['token-1']);
    expect(user.falseAlarmCount, 2);
    expect(user.createdAt!.isAtSameMomentAs(createdAt), isTrue);
    expect(user.firstName, 'Kwame');
  });

  test('toMap is the inverse of fromMap', () {
    expect(AppUser.fromMap('uid-1', map).toMap(), map);
  });

  test('missing optional fields get safe defaults', () {
    final user = AppUser.fromMap('uid-2', {'fullName': 'Efua Addo'});
    expect(user.role, isNull);
    expect(user.verified, isFalse);
    expect(user.deactivated, isFalse);
    expect(user.fcmTokens, isEmpty);
  });

  test('copyWith changes only the given fields', () {
    final user = AppUser.fromMap('uid-1', map).copyWith(onDuty: true);
    expect(user.onDuty, isTrue);
    expect(user.fullName, 'Kwame Mensah');
  });
}
