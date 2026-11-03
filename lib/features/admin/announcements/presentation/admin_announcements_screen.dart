import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notifications/presentation/announcements_screen.dart';
import '../../../notifications/providers.dart';
import '../../widgets/page_header.dart';
import '../../widgets/section_card.dart';
import '../../widgets/status_views.dart';
import 'announcement_composer.dart';

/// Post announcements and see what has been sent (PRD §4.7).
class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Admins see every audience.
    final sent = ref.watch(announcementsProvider);
    final count = sent.value?.length;
    final history = SectionCard(
      title: 'Sent',
      subtitle: count == null
          ? null
          : '$count announcement${count == 1 ? '' : 's'}',
      icon: Icons.outbox_outlined,
      expand: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: sent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState.error('announcements'),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'Nothing sent yet',
                message: 'Announcements you send will be listed here.',
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    AnnouncementCard(announcement: list[i], showAudience: true),
              ),
      ),
    );
    const header = PageHeader(
      title: 'Announcements',
      subtitle:
          'Send safety notices to phones. Each one arrives as a '
          'notification.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return ListView(
            padding: kPagePadding,
            children: [
              header,
              const AnnouncementComposer(),
              const SizedBox(height: kGap),
              SizedBox(height: 520, child: history),
            ],
          );
        }
        return Padding(
          padding: kPagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 500,
                      child: SingleChildScrollView(
                        child: AnnouncementComposer(),
                      ),
                    ),
                    const SizedBox(width: kGap),
                    Expanded(child: history),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
