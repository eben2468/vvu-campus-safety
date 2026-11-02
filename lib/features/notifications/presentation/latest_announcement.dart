import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../providers.dart';
import 'announcements_screen.dart';

/// The newest announcement with a link to the full list. Hidden when there
/// are none.
class LatestAnnouncement extends ConsumerWidget {
  const LatestAnnouncement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(announcementsProvider).value?.firstOrNull;
    if (latest == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnnouncementCard(announcement: latest, maxLines: 3),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(Routes.announcements),
            child: const Text('All announcements'),
          ),
        ),
      ],
    );
  }
}
