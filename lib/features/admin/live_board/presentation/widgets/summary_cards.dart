import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../providers.dart';
import '../../../widgets/stat_card.dart';

/// The four numbers at the top of the live board (PRD §4.8).
class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    String duration(Duration? d) => d == null ? '—' : formatDuration(d);

    return StatRow(
      cards: [
        StatCard(
          label: 'Active now',
          value: '${stats.activeNow}',
          icon: Icons.warning_amber_rounded,
          color: stats.activeNow > 0 ? AppColors.sosRed : AppColors.safeGreen,
          detail: stats.activeNow > 0 ? 'Needs attention' : 'Nothing open',
        ),
        StatCard(
          label: "Today's incidents",
          value: '${stats.todayTotal}',
          icon: Icons.today_outlined,
          detail: 'SOS alerts and reports',
        ),
        StatCard(
          label: 'Average response',
          value: duration(stats.avgResponseToday),
          icon: Icons.timer_outlined,
          color: AppColors.inProgress,
          detail: 'Today · 7 days: ${duration(stats.avgResponseWeek)}',
        ),
        StatCard(
          label: 'Resolved today',
          value: '${stats.resolvedToday}',
          icon: Icons.task_alt,
          color: AppColors.safeGreen,
          detail: 'Closed by security',
        ),
      ],
    );
  }
}
