import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../providers.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

/// Chat between the reporter and security about one incident (PRD §4.6).
/// Opened from the incident, the alert page or a message notification.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId)).value;
    final messages = ref.watch(chatMessagesProvider(incidentId));
    final me = ref.watch(sessionProvider).profile;

    Future<void> send(String text, Uint8List? photo) async {
      if (incident == null || me == null) return;
      await ref
          .read(chatRepositoryProvider)
          .send(
            incidentId: incidentId,
            reporterId: incident.reporterId,
            sender: me,
            text: text,
            photo: photo,
          );
    }

    final title = incident == null
        ? 'Chat'
        : me?.uid == incident.reporterId
        ? 'Chat with security'
        : 'Chat with ${incident.reporterName}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Could not load messages.')),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No messages yet. Write below to talk about this incident.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true, // newest at the bottom, next to the input
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final message = list[list.length - 1 - i];
                        return MessageBubble(
                          message: message,
                          mine: message.senderId == me?.uid,
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1),
          if (incident != null && !incident.active)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'This incident is closed. You can still send a message.',
              ),
            ),
          ChatInput(onSend: send),
        ],
      ),
    );
  }
}
