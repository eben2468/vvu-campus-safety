import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/announcement.dart';
import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../providers.dart';

/// Campus safety announcements for the user's audience, newest first.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Could not load announcements.')),
        data: (list) => list.isEmpty
            ? const InfoPanel(
                icon: Icons.campaign_outlined,
                heading: 'No announcements',
                message:
                    'Safety notices from the Security Office will appear here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => AnnouncementCard(announcement: list[i]),
              ),
      ),
    );
  }
}

/// One announcement: title, date and body.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.maxLines,
    this.showAudience = false,
  });

  final Announcement announcement;

  /// Clamp the body (e.g. on the home screen); null shows it all.
  final int? maxLines;

  /// Adds who it was sent to after the date (the admin's list).
  final bool showAudience;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final createdAt = announcement.createdAt;
    final details = [
      if (createdAt != null) formatDateTime(createdAt),
      if (showAudience) 'Sent to ${announcement.audience.name}',
    ].join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(announcement.title, style: textTheme.titleMedium),
                ),
              ],
            ),
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(details, style: textTheme.bodySmall),
              ),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              maxLines: maxLines,
              overflow: maxLines == null ? null : TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
