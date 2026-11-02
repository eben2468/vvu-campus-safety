import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../providers.dart';

/// The four numbers at the top of the live board (PRD §4.8).
class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    String duration(Duration? d) => d == null ? '—' : formatDuration(d);

    final cards = [
      _SummaryCard(
        label: 'Active now',
        value: '${stats.activeNow}',
        icon: Icons.warning_amber,
        color: stats.activeNow > 0 ? AppColors.sosRed : null,
      ),
      _SummaryCard(
        label: "Today's incidents",
        value: '${stats.todayTotal}',
        icon: Icons.today,
      ),
      _SummaryCard(
        label: 'Average response',
        value: duration(stats.avgResponseToday),
        detail: 'Today · 7 days: ${duration(stats.avgResponseWeek)}',
        icon: Icons.timer,
      ),
      _SummaryCard(
        label: 'Resolved today',
        value: '${stats.resolvedToday}',
        icon: Icons.task_alt,
        color: AppColors.safeGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Four across on a desktop, two across on a narrow window.
        final perRow = constraints.maxWidth >= 900 ? 4 : 2;
        final width = (constraints.maxWidth - 12 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.labelLarge),
                  Text(
                    value,
                    style: textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (detail != null) Text(detail!, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
