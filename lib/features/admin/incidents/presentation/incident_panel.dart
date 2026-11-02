import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme.dart';
import '../../../incidents/presentation/widgets/chat_view.dart';
import '../../../incidents/presentation/widgets/status_chip.dart';
import '../../../incidents/providers.dart';
import 'widgets/incident_details.dart';

/// Slides the incident panel in from the right, over whichever dashboard
/// page is open (live board, incidents table, new-SOS banner).
Future<void> showIncidentPanel(BuildContext context, String incidentId) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close incident',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: IncidentPanel(incidentId: incidentId),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
      child: child,
    ),
  );
}

/// One incident with every response action (PRD §4.8): details and
/// timeline in one tab, the chat with the reporter in the other.
class IncidentPanel extends ConsumerWidget {
  const IncidentPanel({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    final width = MediaQuery.sizeOf(context).width;
    final loaded = incident.value;

    return Material(
      elevation: 8,
      child: SizedBox(
        width: width < 560 ? width : 520,
        height: double.infinity,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text(
                  loaded == null
                      ? 'Incident'
                      : loaded.isSos
                      ? 'SOS — ${loaded.reporterName}'
                      : '${loaded.category} — ${loaded.reporterName}',
                  style: TextStyle(
                    color: loaded?.isSos == true ? AppColors.sosRed : null,
                  ),
                ),
                actions: [
                  if (loaded != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: StatusChip(loaded.status),
                    ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Details'),
                    Tab(text: 'Chat'),
                  ],
                ),
              ),
              Expanded(
                child: incident.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Could not load this incident.'),
                  ),
                  data: (incident) => incident == null
                      ? const Center(
                          child: Text('This incident no longer exists.'),
                        )
                      : TabBarView(
                          children: [
                            IncidentDetails(incident: incident),
                            ChatView(incidentId: incident.id),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
