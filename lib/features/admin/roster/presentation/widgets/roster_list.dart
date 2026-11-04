import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme.dart';
import '../../../../../models/roster_entry.dart';
import '../../../data/admin_repository.dart';
import '../../../data/roster_filter.dart';
import '../../../providers.dart';
import '../../../widgets/page_header.dart';
import '../../../widgets/status_views.dart';
import 'roster_table.dart';

/// Everything imported so far, with search, a status filter and pages.
class RosterList extends ConsumerStatefulWidget {
  const RosterList({super.key});

  @override
  ConsumerState<RosterList> createState() => _RosterListState();
}

class _RosterListState extends ConsumerState<RosterList> {
  static const _pageSize = 50;

  RosterFilter _filter = RosterFilter.all;
  String _search = '';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(rosterProvider);
    final entries = roster.value ?? const <RosterEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<RosterFilter>(
                  showSelectedIcon: false,
                  segments: [
                    for (final f in RosterFilter.values)
                      ButtonSegment(
                        value: f,
                        label: Text(
                          '${f.label} (${entries.where(f.includes).length})',
                        ),
                      ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() {
                    _filter = s.single;
                    _page = 0;
                  }),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search ID, name or department',
                    ),
                    onChanged: (text) => setState(() {
                      _search = text;
                      _page = 0;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kGap),
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: roster.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const EmptyState.error('the roster'),
              data: _results,
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(List<RosterEntry> entries) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No IDs imported yet',
        message: 'Use Import a file to add the list from the Registry or HR.',
      );
    }
    final shown = [
      for (final entry in entries)
        if (_filter.includes(entry) && rosterEntryMatches(entry, _search))
          entry,
    ];
    if (shown.isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'No IDs match',
        message: 'Try another search or filter.',
      );
    }
    // The list updates live, so it can shrink past the current page.
    final lastPage = (shown.length - 1) ~/ _pageSize;
    final page = _page.clamp(0, lastPage);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, shown.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: RosterTable(entries: shown.sublist(start, end))),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entries.length >= AdminRepository.rosterViewLimit
                      ? 'Only the first ${AdminRepository.rosterViewLimit} '
                            'IDs are listed here. Every imported ID can '
                            'still register.'
                      : '',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
              Text('${start + 1}–$end of ${shown.length}'),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Previous page',
                icon: const Icon(Icons.chevron_left),
                onPressed: page == 0
                    ? null
                    : () => setState(() => _page = page - 1),
              ),
              IconButton(
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right),
                onPressed: page == lastPage
                    ? null
                    : () => setState(() => _page = page + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
