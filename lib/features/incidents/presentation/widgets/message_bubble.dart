import 'package:flutter/material.dart';

import '../../../../core/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/chat_message.dart';
import 'photo_gallery.dart';

/// One chat message. Mine on the right; security's messages are labelled
/// so the reporter knows who is answering.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timestamp = message.timestamp;
    final meta = [
      if (!mine)
        message.fromSecurity
            ? '${message.senderName} (Security)'
            : message.senderName,
      if (message.pendingSync)
        'Sending…'
      else if (timestamp != null)
        formatTime(timestamp),
    ].join(' · ');

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: mine
                ? scheme.primaryContainer
                : message.fromSecurity
                ? AppColors.vvuGold.withValues(alpha: 0.2)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageUrl != null) ...[
                PhotoGallery(urls: [message.imageUrl!]),
                const SizedBox(height: 6),
              ],
              if (message.text.isNotEmpty)
                Text(message.text, style: textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(meta, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
