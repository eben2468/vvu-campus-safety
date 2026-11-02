import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/constants.dart';
import 'package:vvu_campus_safety/features/incidents/data/incident_repository.dart';
import 'package:vvu_campus_safety/models/announcement.dart';
import 'package:vvu_campus_safety/models/app_user.dart';
import 'package:vvu_campus_safety/models/chat_message.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

void main() {
  test('ChatMessage round-trips and knows who is security', () {
    final map = {
      'senderId': 'officer1',
      'senderName': 'Test Officer',
      'senderRole': 'officer',
      'text': 'On my way',
      'imageUrl': null,
      'timestamp': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
    };
    final message = ChatMessage.fromMap('m1', map);
    expect(message.fromSecurity, isTrue);
    expect(message.toMap(), map);
    expect(
      ChatMessage.fromMap('m2', {...map, 'senderRole': 'student'}).fromSecurity,
      isFalse,
    );
  });

  group('Announcement', () {
    test('round-trips', () {
      final map = {
        'title': 'Night escort',
        'body': 'After 10 pm.',
        'audience': 'students',
        'createdBy': 'admin1',
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2)),
      };
      final a = Announcement.fromMap('a1', map);
      expect(a.audience, AnnouncementAudience.students);
      expect(a.toMap(), map);
    });

    test('each role sees "all" plus its own group; admins see everything', () {
      expect(Announcement.visibleTo(UserRole.student), [
        AnnouncementAudience.all,
        AnnouncementAudience.students,
      ]);
      expect(
        Announcement.visibleTo(UserRole.officer),
        contains(AnnouncementAudience.officers),
      );
      expect(
        Announcement.visibleTo(UserRole.staff),
        isNot(contains(AnnouncementAudience.students)),
      );
      expect(
        Announcement.visibleTo(UserRole.admin),
        AnnouncementAudience.values,
      );
    });
  });

  group('IncidentRepository.canActOn', () {
    AppUser user(String uid, UserRole role) =>
        AppUser(uid: uid, fullName: uid, email: '', phone: '', role: role);
    final officer = user('officer1', UserRole.officer);
    final other = user('officer2', UserRole.officer);
    final admin = user('admin1', UserRole.admin);

    test('assigned officers can go on scene and resolve', () {
      for (final to in [IncidentStatus.onScene, IncidentStatus.resolved]) {
        expect(IncidentRepository.canActOn(['officer1'], officer, to), isTrue);
        expect(IncidentRepository.canActOn(['officer1'], other, to), isFalse);
        expect(IncidentRepository.canActOn(['officer1'], admin, to), isTrue);
      }
    });

    test('anyone on the team can mark a false alarm', () {
      expect(
        IncidentRepository.canActOn(
          ['officer1'],
          other,
          IncidentStatus.falseAlarm,
        ),
        isTrue,
      );
    });
  });
}
