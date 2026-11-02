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
    if (arrived.isNotEmpty) {
      playAlertTone();
      _unseen.addAll(arrived.map((i) => i.id));
    }
    // The first call comes from initState and never changes anything.
    if (arrived.isNotEmpty || _unseen.length != before) {
      setState(() {});
      _updateFlash();
    }
  }

  void _updateFlash() {
    if (_unseen.isEmpty) {
      _flash?.cancel();
      _flash = null;
    } else {
      _flash ??= Timer.periodic(
        const Duration(milliseconds: 600),
        (_) => setState(() => _bright = !_bright),
      );
    }
  }

  void _dismiss([String? id]) {
    setState(() => id == null ? _unseen.clear() : _unseen.remove(id));
    _updateFlash();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
