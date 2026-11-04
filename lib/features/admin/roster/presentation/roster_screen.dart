import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../widgets/page_header.dart';
import 'widgets/roster_import_panel.dart';
import 'widgets/roster_list.dart';

enum _RosterTab { imported, upload }

/// The Registry's list of student and staff IDs (PRD §4.11), which
/// `verifyId` checks when someone registers: what has been imported, and
/// importing more.
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  _RosterTab _tab = _RosterTab.imported;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(rosterProvider).value?.length;

    return Padding(
      padding: kPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'ID roster',
            subtitle:
                'Students and staff can only register with an ID on this '
                'list.',
            actions: [
              SegmentedButton<_RosterTab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _RosterTab.imported,
                    label: Text(
                      count == null ? 'Imported IDs' : 'Imported IDs ($count)',
                    ),
                  ),
                  const ButtonSegment(
                    value: _RosterTab.upload,
                    label: Text('Import a file'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.single),
              ),
            ],
          ),
          // A stack, so a chosen file survives a look at the other tab.
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              sizing: StackFit.expand,
              children: const [RosterList(), RosterImportPanel()],
            ),
          ),
        ],
      ),
    );
  }
}
