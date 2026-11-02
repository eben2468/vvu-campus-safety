import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../providers.dart';
import 'widgets/chat_view.dart';

/// Chat between the reporter and security about one incident (PRD §4.6).
/// Opened from the incident, the alert page or a message notification.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId)).value;
    final me = ref.watch(sessionProvider).profile;

    final title = incident == null
        ? 'Chat'
        : me?.uid == incident.reporterId
        ? 'Chat with security'
        : 'Chat with ${incident.reporterName}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ChatView(incidentId: incidentId),
    );
  }
}
