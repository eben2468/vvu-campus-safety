import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/app_settings.dart';
import '../../../../models/incident.dart';
import '../../../officer/presentation/widgets/incident_card.dart';
import '../../../officer/providers.dart';
import '../../../sos/providers.dart';
import '../../incidents/presentation/incident_panel.dart';
import 'widgets/activity_feed.dart';
import 'widgets/campus_map.dart';
import 'widgets/summary_cards.dart';

/// The dashboard's landing page (PRD §4.8): summary cards, the campus map
/// with open incidents, the open-incident list and recent activity, all
/// updating live. New SOS alerts also sound and flash (see NewSosBanner).
class LiveBoardScreen extends ConsumerWidget {
  const LiveBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeIncidentsProvider);
    final incidents = active.value ?? const <Incident>[];
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    void open(Incident incident) => showIncidentPanel(context, incident.id);

    final map = Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: CampusMap(incidents: incidents, settings: settings, onOpen: open),
    );
    final list = _Section(
      title: 'Open incidents (${incidents.length})',
      child: active.hasError
          ? const Center(child: Text('Could not load incidents.'))
          : incidents.isEmpty
          ? const Center(child: Text('No open incidents. All quiet.'))
          : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (_, i) => IncidentCard(
                incident: incidents[i],
                onTap: () => open(incidents[i]),
              ),
            ),
    );
    const feed = _Section(title: 'Recent activity', child: ActivityFeed());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1000) {
            // Narrow window: stack everything and scroll.
            return ListView(
              children: [
                const SummaryCards(),
                const SizedBox(height: 12),
                SizedBox(height: 360, child: map),
                const SizedBox(height: 12),
                SizedBox(height: 400, child: list),
                const SizedBox(height: 12),
                const SizedBox(height: 320, child: feed),
              ],
            );
          }
          return Column(
            children: [
              const SummaryCards(),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: map),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          Expanded(flex: 3, child: list),
                          const SizedBox(height: 12),
                          const Expanded(flex: 2, child: feed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A titled card that fills the space it is given.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
