import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/incident.dart';
import '../../../services/alert_sound.dart';
import '../../officer/providers.dart';
import '../data/new_sos_tracker.dart';
import '../incidents/presentation/incident_panel.dart';

/// Sounds an alarm and shows a flashing red banner when an SOS arrives
/// while the dashboard is open (PRD §4.8). The banner stays until the SOS
/// is accepted, opened or dismissed.
class NewSosBanner extends ConsumerStatefulWidget {
  const NewSosBanner({super.key});

  @override
  ConsumerState<NewSosBanner> createState() => _NewSosBannerState();
}

class _NewSosBannerState extends ConsumerState<NewSosBanner> {
  final _tracker = NewSosTracker();

  /// Ids of new SOS alerts nobody has opened or dismissed yet.
  final _unseen = <String>[];
  Timer? _flash;
  Timer? _alarm;
  bool _bright = true;

  @override
  void initState() {
    super.initState();
    // fireImmediately: the list may already be loaded by another page, and
    // the tracker needs it as its starting point.
    ref.listenManual(activeIncidentsProvider, (_, next) {
      if (next.value case final active?) _onActive(active);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _flash?.cancel();
    _alarm?.cancel();
    super.dispose();
  }

  void _onActive(List<Incident> active) {
    final arrived = _tracker.update(active);
    // Drop alerts an officer has accepted or that were closed.
    final waiting = {
      for (final i in active)
        if (NewSosTracker.isWaiting(i)) i.id,
    };
    final before = _unseen.length;
    _unseen.removeWhere((id) => !waiting.contains(id));
    _unseen.addAll(arrived.map((i) => i.id));
    // The first call comes from initState and never changes anything.
    if (arrived.isNotEmpty || _unseen.length != before) {
      setState(() {});
      _updateAlarm();
    }
  }

  /// Flashes and sounds until nothing is waiting, in case nobody is at the
  /// desk when the SOS arrives.
  void _updateAlarm() {
    if (_unseen.isEmpty) {
      _flash?.cancel();
      _flash = null;
      _alarm?.cancel();
      _alarm = null;
    } else {
      if (_alarm == null) {
        playAlertTone();
        _alarm = Timer.periodic(
          const Duration(seconds: 4),
          (_) => playAlertTone(),
        );
      }
      _flash ??= Timer.periodic(
        const Duration(milliseconds: 600),
        (_) => setState(() => _bright = !_bright),
      );
    }
  }

  void _dismiss([String? id]) {
    setState(() => id == null ? _unseen.clear() : _unseen.remove(id));
    _updateAlarm();
  }

  @override
  Widget build(BuildContext context) {
    if (_unseen.isEmpty) return const SizedBox.shrink();

    final active = ref.watch(activeIncidentsProvider).value ?? const [];
    final latest = active.where((i) => i.id == _unseen.last).firstOrNull;
    final count = _unseen.length;
    final text = count == 1
        ? 'New SOS from ${latest?.reporterName ?? 'a user'}'
              '${latest?.locationLabel == null ? '' : ' near ${latest!.locationLabel}'}'
        : '$count new SOS alerts';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _bright ? AppColors.sosRed : const Color(0xFF8B0000),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sos, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.sosRed,
            ),
            onPressed: () {
              final id = _unseen.last;
              _dismiss(id);
              showIncidentPanel(context, id);
            },
            child: const Text('View'),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _dismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
