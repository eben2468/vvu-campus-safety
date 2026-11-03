import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants.dart';
import '../../../../sos/providers.dart';
import '../../../providers.dart';

/// Date range and category for the analytics page.
class AnalyticsFilters extends ConsumerWidget {
  const AnalyticsFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final notifier = ref.read(analyticsFilterProvider.notifier);
    final categories =
        ref.watch(appSettingsProvider).value?.categories ?? defaultCategories;
    final format = DateFormat('d MMM yyyy');

    Future<void> pickRange() async {
      final now = DateTime.now().toUtc();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime.utc(2024),
        lastDate: DateTime.utc(now.year, now.month, now.day),
        initialDateRange: DateTimeRange(start: filter.from, end: filter.to),
        helpText: 'Incidents raised between',
      );
      if (picked == null) return;
      // The picker returns local midnights; keep the calendar dates in UTC.
      DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);
      notifier.setRange(day(picked.start), day(picked.end));
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: pickRange,
          icon: const Icon(Icons.date_range),
          label: Text(
            '${format.format(filter.from)} – ${format.format(filter.to)}',
          ),
        ),
        DropdownMenu<String?>(
          width: 220,
          leadingIcon: const Icon(Icons.category_outlined),
          initialSelection: filter.category,
          onSelected: notifier.setCategory,
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'All incidents'),
            const DropdownMenuEntry(value: 'SOS', label: 'SOS alerts'),
            for (final c in categories) DropdownMenuEntry(value: c, label: c),
          ],
        ),
      ],
    );
  }
}
