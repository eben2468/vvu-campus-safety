import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/incident.dart';
import '../../../officer/presentation/widgets/incident_card.dart';
import '../../../officer/providers.dart';
import '../../../sos/providers.dart';
import '../../incidents/presentation/incident_panel.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_views.dart';
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

    final map = SectionCard(
      title: 'Campus map',
      subtitle: 'Red pins are SOS alerts, blue pins are reports',
      icon: Icons.map_outlined,
      expand: true,
      padding: EdgeInsets.zero,
      child: CampusMap(incidents: incidents, settings: settings, onOpen: open),
    );
    final list = SectionCard(
      title: 'Open incidents',
      icon: Icons.notifications_active_outlined,
      trailing: Pill(
        '${incidents.length}',
        color: incidents.isEmpty ? AppColors.safeGreen : AppColors.sosRed,
      ),
      expand: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: active.hasError
          ? const EmptyState.error('incidents')
          : incidents.isEmpty
          ? const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'All quiet',
              message: 'There are no open incidents right now.',
            )
          : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (_, i) => IncidentCard(
                incident: incidents[i],
                onTap: () => open(incidents[i]),
              ),
            ),
    );
    const feed = SectionCard(
      title: 'Recent activity',
      icon: Icons.bolt_outlined,
      expand: true,
      padding: EdgeInsets.only(bottom: 8),
      child: ActivityFeed(),
    );
    const header = PageHeader(
      title: 'Live board',
      subtitle: 'Open incidents and what security is doing about them.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000 || constraints.maxHeight < 640) {
          // Narrow or short window: stack everything and scroll.
          return ListView(
            padding: kPagePadding,
            children: [
              header,
              const SummaryCards(),
              const SizedBox(height: kGap),
              SizedBox(height: 420, child: map),
              const SizedBox(height: kGap),
              SizedBox(height: 420, child: list),
              const SizedBox(height: kGap),
              const SizedBox(height: 360, child: feed),
            ],
          );
        }
        return Padding(
          padding: kPagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SummaryCards(),
              const SizedBox(height: kGap),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: map),
                    const SizedBox(width: kGap),
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          Expanded(flex: 3, child: list),
                          const SizedBox(height: kGap),
                          const Expanded(flex: 2, child: feed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
