import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../models/incident.dart';
import '../../../../models/incident_status.dart';
import '../../../auth/providers.dart';
import '../../../incidents/data/incident_repository.dart';
import '../../../incidents/providers.dart';
import 'action_dialogs.dart';

/// The response buttons on an alert (PRD §4.5), limited to the moves the
/// state machine allows for this incident and this officer.
class OfficerActions extends ConsumerStatefulWidget {
  const OfficerActions({super.key, required this.incident});

  final Incident incident;

  @override
  ConsumerState<OfficerActions> createState() => _OfficerActionsState();
}

class _OfficerActionsState extends ConsumerState<OfficerActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(IncidentStatus to) async {
    final note = await askForNote(
      context,
      title: to == IncidentStatus.resolved
          ? 'Resolve incident'
          : 'Mark as false alarm',
      hint: to == IncidentStatus.resolved
          ? 'What was done (optional)'
          : 'Why (optional)',
      confirmLabel: to == IncidentStatus.resolved ? 'Resolve' : 'False alarm',
    );
    if (note == null) return; // cancelled
    await _status(to, note: note);
  }

  Future<void> _status(IncidentStatus to, {String note = ''}) {
    final officer = ref.read(sessionProvider).profile!;
    return _run(
      () => ref
          .read(incidentRepositoryProvider)
          .updateStatus(widget.incident.id, to, officer, note: note),
      'Marked ${to.label.toLowerCase()}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final officer = ref.watch(sessionProvider).profile;
    final incident = widget.incident;
    if (officer == null || incident.status.isClosed) {
      return const SizedBox.shrink();
    }

    final repo = ref.read(incidentRepositoryProvider);
    bool can(IncidentStatus to) =>
        incident.status.canTransition(to, by: StatusActor.officer) &&
        IncidentRepository.canActOn(incident.assignedTo, officer, to);
    // Buttons are disabled while an action is running.
    VoidCallback? unlessBusy(VoidCallback action) => _busy ? null : action;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incident.status == IncidentStatus.alerted)
          FilledButton.icon(
            onPressed: unlessBusy(
              () => _run(
                () => repo.accept(incident.id, officer),
                'Alert accepted.',
              ),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
          ),
        if (can(IncidentStatus.onScene))
          FilledButton.icon(
            onPressed: unlessBusy(() => _status(IncidentStatus.onScene)),
            icon: const Icon(Icons.place),
            label: const Text("I'm on scene"),
          ),
        if (can(IncidentStatus.resolved)) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: unlessBusy(() => _close(IncidentStatus.resolved)),
            icon: const Icon(Icons.task_alt),
            label: const Text('Resolve'),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: unlessBusy(() async {
                  final assignee = await pickOfficer(
                    context,
                    exclude: incident.assignedTo,
                  );
                  if (assignee == null) return;
                  await _run(
                    () => repo.assign(
                      incident.id,
                      assignee: assignee,
                      by: officer,
                    ),
                    '${assignee.fullName} assigned.',
                  );
                }),
                icon: const Icon(Icons.group_add),
                label: const Text('Assign'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: unlessBusy(() async {
                  final note = await askForNote(
                    context,
                    title: 'Add note',
                    hint: 'What you saw or did',
                    confirmLabel: 'Save',
                    required: true,
                  );
                  if (note == null) return;
                  await _run(
                    () => repo.addNote(incident.id, officer, note),
                    'Note added.',
                  );
                }),
                icon: const Icon(Icons.note_add),
                label: const Text('Add note'),
              ),
            ),
          ],
        ),
        if (can(IncidentStatus.falseAlarm))
          TextButton(
            onPressed: unlessBusy(() => _close(IncidentStatus.falseAlarm)),
            child: const Text('Mark as false alarm'),
          ),
      ],
    );
  }
}
