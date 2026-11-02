import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/incident.dart';
import '../../../../services/file_download.dart';
import '../../../sos/providers.dart';
import '../../data/analytics.dart';
import '../../data/dashboard_stats.dart';
import '../../providers.dart';
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
      padding: const EdgeInsets.all(16),
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        AnalyticsFilters(
          trailing: FilledButton.icon(
            onPressed: list.isEmpty ? null : export,
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
        ),
        const SizedBox(height: 12),
        if (incidents.isLoading && !incidents.hasValue)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (incidents.hasError)
          const Text('Could not load incidents.')
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
    final located = incidents.where(
      (i) => (i.location ?? i.lastLocation) != null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        Widget sized(Widget child) => SizedBox(width: half, child: child);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${incidents.length} incidents · '
              '${incidents.where((i) => i.isSos).length} SOS · '
              'average response ${average == null ? '—' : formatDuration(average)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ChartCard(
              title:
                  'Where incidents happened (${located.length} with a location)',
              height: 420,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: HeatmapMap(
                  cells: heatCells(located),
                  settings: settings,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                sized(
                  ChartCard(
                    title: 'Incidents by category',
                    child: CategoryChart(counts: countByCategory(incidents)),
                  ),
                ),
                sized(
                  ChartCard(
                    title: 'Incidents per week',
                    child: WeeklyCountChart(weeks: weeks),
                  ),
                ),
                sized(
                  ChartCard(
                    title: 'Average response time per week',
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
