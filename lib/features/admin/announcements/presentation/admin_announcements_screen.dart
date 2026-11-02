import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/announcements_screen.dart';
import '../../../notifications/providers.dart';
import 'announcement_composer.dart';

/// Post announcements and see what has been sent (PRD §4.7).
class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Admins see every audience.
    final sent = ref.watch(announcementsProvider);
    final history = sent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('Could not load announcements.')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('Nothing sent yet.'))
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  AnnouncementCard(announcement: list[i], showAudience: true),
            ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = Text(
            'Announcements',
            style: Theme.of(context).textTheme.headlineSmall,
          );
          if (constraints.maxWidth < 900) {
            return ListView(
              children: [
                title,
                const SizedBox(height: 12),
                const AnnouncementComposer(),
                const SizedBox(height: 16),
                SizedBox(height: 500, child: history),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 520,
                      child: SingleChildScrollView(
                        child: AnnouncementComposer(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: history),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
