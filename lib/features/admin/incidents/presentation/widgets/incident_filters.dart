import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants.dart';
import '../../../../sos/providers.dart';
import '../../../data/incident_filter.dart';
import '../../../providers.dart';

/// Search box and drop-downs above the incidents table.
class IncidentFilters extends ConsumerWidget {
  const IncidentFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(incidentFilterProvider);
    final categories =
        ref.watch(appSettingsProvider).value?.categories ?? defaultCategories;
    void set(IncidentFilter next) =>
        ref.read(incidentFilterProvider.notifier).set(next);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search reporter, place or status',
              isDense: true,
            ),
            onChanged: (text) => set(filter.copyWith(search: text)),
          ),
        ),
        SegmentedButton<StatusFilter>(
          segments: [
            for (final s in StatusFilter.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {filter.status},
          onSelectionChanged: (s) => set(filter.copyWith(status: s.single)),
        ),
        DropdownMenu<IncidentKind?>(
          label: const Text('Type'),
          initialSelection: filter.kind,
          onSelected: (kind) => set(filter.copyWith(kind: () => kind)),
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: null, label: 'SOS and reports'),
            DropdownMenuEntry(value: IncidentKind.sos, label: 'SOS only'),
            DropdownMenuEntry(
              value: IncidentKind.report,
              label: 'Reports only',
            ),
          ],
        ),
        DropdownMenu<String?>(
          label: const Text('Category'),
          initialSelection: filter.category,
          onSelected: (category) =>
              set(filter.copyWith(category: () => category)),
          dropdownMenuEntries: [
            const DropdownMenuEntry(value: null, label: 'All categories'),
            for (final c in categories) DropdownMenuEntry(value: c, label: c),
          ],
        ),
      ],
    );
  }
}
