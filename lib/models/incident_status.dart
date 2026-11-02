/// Who is attempting an incident status change.
enum StatusActor {
  /// The student or staff member who raised the incident.
  reporter,

  /// An officer or admin.
  officer,

  /// A Cloud Function (e.g. `onIncidentCreated`).
  system,
}

/// Incident status — the fixed six-value state machine from
/// docs/ARCHITECTURE.md §4.
///
/// A reporter cancelling ("I'm safe") is stored as [resolved] with
/// `cancelledByReporter: true`, so there is no separate "cancelled" status.
enum IncidentStatus {
  newIncident('new'), // `new` is a Dart keyword
  alerted('alerted'),
  accepted('accepted'),
  onScene('on_scene'),
  resolved('resolved'),
  falseAlarm('false_alarm');

  const IncidentStatus(this.value);

  /// The string stored in Firestore.
  final String value;

  static IncidentStatus fromValue(String value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw ArgumentError.value(value, 'value', 'Unknown status'),
  );

  /// Allowed transitions per actor. Anything not listed is refused.
  static const _allowed =
      <StatusActor, Map<IncidentStatus, Set<IncidentStatus>>>{
        StatusActor.system: {
          newIncident: {alerted},
        },
        StatusActor.reporter: {
          newIncident: {resolved},
          alerted: {resolved},
        },
        StatusActor.officer: {
          alerted: {accepted, falseAlarm},
          accepted: {onScene, resolved, falseAlarm},
          onScene: {resolved, falseAlarm},
        },
      };

  /// Whether [by] may move an incident from this status to [to].
  /// Mirrors the checks in `firestore.rules`.
  bool canTransition(IncidentStatus to, {required StatusActor by}) =>
      _allowed[by]?[this]?.contains(to) ?? false;

  /// Resolved and false-alarm incidents are closed for good.
  bool get isClosed => this == resolved || this == falseAlarm;

  bool get isActive => !isClosed;

  /// Plain-English label for chips and timelines.
  String get label => switch (this) {
    newIncident => 'New',
    alerted => 'Alerted',
    accepted => 'Accepted',
    onScene => 'On scene',
    resolved => 'Resolved',
    falseAlarm => 'False alarm',
  };
}
