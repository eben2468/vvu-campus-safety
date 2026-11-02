import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/launchers.dart';
import '../../../../models/incident.dart';
import '../../providers.dart';

/// Shown while the SOS hasn't reached the server (no data connection).
/// The alert is queued and sends itself later; meanwhile the user can call
/// or text the Security Office directly (docs/PRD.md §4.2).
class OfflineFallbackCard extends ConsumerWidget {
  const OfflineFallbackCard({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(appSettingsProvider).value?.securityPhone ?? '';
    final location = incident.currentLocation;
    final smsBody = [
      'SOS from ${incident.reporterName} (VVU Campus Safety).',
      if (incident.locationLabel != null) 'Near ${incident.locationLabel}.',
      if (location != null) mapsLink(location.latitude, location.longitude),
    ].join(' ');

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.wifi_off),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No connection yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Your alert will send automatically as soon as you are back '
              'online. Contact security now as well:',
            ),
            if (phone.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Call the Security Office or someone near you.'),
              )
            else ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => callNumber(phone),
                icon: const Icon(Icons.call),
                label: const Text('Call security'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => textNumber(phone, smsBody),
                icon: const Icon(Icons.sms),
                label: const Text('Text security my location'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
