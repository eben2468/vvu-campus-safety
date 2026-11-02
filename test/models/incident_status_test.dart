import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

void main() {
  test('round-trips the Firestore values', () {
    for (final status in IncidentStatus.values) {
      expect(IncidentStatus.fromValue(status.value), status);
    }
    expect(IncidentStatus.newIncident.value, 'new');
    expect(IncidentStatus.onScene.value, 'on_scene');
    expect(() => IncidentStatus.fromValue('cancelled'), throwsArgumentError);
  });

  group('canTransition', () {
    const s = IncidentStatus.values;

    /// Every (from, to) pair the actor may make, per docs/ARCHITECTURE.md §4.
    const allowed = {
      StatusActor.system: {('new', 'alerted')},
      StatusActor.reporter: {('new', 'resolved'), ('alerted', 'resolved')},
      StatusActor.officer: {
        ('alerted', 'accepted'),
        ('alerted', 'false_alarm'),
        ('accepted', 'on_scene'),
        ('accepted', 'resolved'),
        ('accepted', 'false_alarm'),
        ('on_scene', 'resolved'),
        ('on_scene', 'false_alarm'),
      },
    };

    for (final actor in StatusActor.values) {
      test('${actor.name} may make exactly the documented moves', () {
        for (final from in s) {
          for (final to in s) {
            final expected = allowed[actor]!.contains((from.value, to.value));
            expect(
              from.canTransition(to, by: actor),
              expected,
              reason: '${actor.name}: ${from.value} -> ${to.value}',
            );
          }
        }
      });
    }

    test('a reporter cannot cancel once an officer has accepted', () {
      expect(
        IncidentStatus.accepted.canTransition(
          IncidentStatus.resolved,
          by: StatusActor.reporter,
        ),
        isFalse,
      );
    });
  });

  test('resolved and false alarm are closed', () {
    expect(IncidentStatus.resolved.isClosed, isTrue);
    expect(IncidentStatus.falseAlarm.isClosed, isTrue);
    expect(IncidentStatus.onScene.isActive, isTrue);
  });
}
