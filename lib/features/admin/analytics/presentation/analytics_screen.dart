import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/incident.dart';
import '../../../../models/incident_status.dart';
import '../../../../services/file_download.dart';
import '../../../sos/providers.dart';
import '../../data/analytics.dart';
import '../../data/dashboard_stats.dart';
import '../../providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_views.dart';
import 'widgets/analytics_filters.dart';
import 'widgets/charts.dart';
import 'widgets/heatmap_map.dart';

/// Heatmap and charts for a date range and category (PRD §4.9), with a CSV
/// export of the same incidents.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(analyticsIncidentsProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final list = incidents.value ?? const <Incident>[];

    void export() {
      final day = DateFormat('yyyy-MM-dd');
      downloadTextFile(
        'vvu-incidents-${day.format(filter.from)}-to-${day.format(filter.to)}.csv',
        incidentsCsv(list),
      );
    }

    return ListView(
      padding: kPagePadding,
      children: [
        PageHeader(
          title: 'Analytics',
          subtitle:
              'Where and when incidents happen, and how fast security '
              'responds.',
          actions: [
            FilledButton.icon(
              onPressed: list.isEmpty ? null : export,
              icon: const Icon(Icons.download),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: AnalyticsFilters(),
          ),
        ),
        const SizedBox(height: kGap),
        if (incidents.isLoading && !incidents.hasValue)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (incidents.hasError)
          const SizedBox(height: 240, child: EmptyState.error('incidents'))
        else
          _Results(
            incidents: list,
            from: filter.from,
            to: filter.to,
            settings:
                ref.watch(appSettingsProvider).value ?? const AppSettings(),
          ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.incidents,
    required this.from,
    required this.to,
    required this.settings,
  });

  final List<Incident> incidents;
  final DateTime from;
  final DateTime to;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final weeks = weeklyStats(incidents, from: from, to: to);
    final average = DashboardStats.averageResponse(incidents);
    final sos = incidents.where((i) => i.isSos).length;
    final falseAlarms = incidents
        .where((i) => i.status == IncidentStatus.falseAlarm)
        .length;
    final located = incidents
        .where((i) => (i.location ?? i.lastLocation) != null)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - kGap) / 2
            : constraints.maxWidth;
        Widget sized(Widget child) => SizedBox(width: half, child: child);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatRow(
              cards: [
                StatCard(
                  label: 'Incidents',
                  value: '${incidents.length}',
                  icon: Icons.report_outlined,
                  detail: '${located.length} with a location',
                ),
                StatCard(
                  label: 'SOS alerts',
                  value: '$sos',
                  icon: Icons.sos,
                  color: AppColors.sosRed,
                  detail: incidents.isEmpty
                      ? 'None in this period'
                      : '${(100 * sos / incidents.length).round()}% of all',
                ),
                StatCard(
                  label: 'Average response',
                  value: average == null ? '—' : formatDuration(average),
                  icon: Icons.timer_outlined,
                  color: AppColors.inProgress,
                  detail: 'Raised to accepted',
                ),
                StatCard(
                  label: 'False alarms',
                  value: '$falseAlarms',
                  icon: Icons.do_not_disturb,
                  color: AppColors.muted,
                  detail: 'Closed as not real',
                ),
              ],
            ),
            const SizedBox(height: kGap),
            ChartCard(
              title: 'Where incidents happened',
              subtitle: 'Bigger, redder circles mean more incidents',
              icon: Icons.map_outlined,
              height: 440,
              padding: EdgeInsets.zero,
              child: HeatmapMap(cells: heatCells(located), settings: settings),
            ),
            const SizedBox(height: kGap),
            Wrap(
              spacing: kGap,
              runSpacing: kGap,
              children: [
                sized(
                  ChartCard(
                    title: 'Incidents by category',
                    icon: Icons.category_outlined,
                    child: CategoryChart(counts: countByCategory(incidents)),
                  ),
                ),
                sized(
                  ChartCard(
                    title: 'Incidents per week',
                    subtitle: 'Weeks start on Monday',
                    icon: Icons.calendar_view_week_outlined,
                    child: WeeklyCountChart(weeks: weeks),
                  ),
                ),
                sized(
                  ChartCard(
                    title: 'Average response time per week',
                    icon: Icons.timer_outlined,
                    child: ResponseTrendChart(weeks: weeks),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
