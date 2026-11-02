import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/location_service.dart';
import '../../providers.dart';

/// Warns on the home screen when location is off, with a way to fix it.
class LocationWarningCard extends ConsumerWidget {
  const LocationWarningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(locationAccessProvider).value;
    if (access == null || access == LocationAccess.granted) {
      return const SizedBox.shrink();
    }

    final service = ref.read(locationServiceProvider);
    final (message, action) = switch (access) {
      LocationAccess.serviceOff => (
        'Location is turned off on this phone.',
        service.openLocationSettings,
      ),
      LocationAccess.deniedForever => (
        'Location is blocked for this app.',
        service.openAppSettings,
      ),
      _ => ('Location is not allowed yet.', service.requestAccess),
    };

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.location_off),
        title: Text(message),
        subtitle: const Text(
          'Without it, security will have to ask where you are.',
        ),
        trailing: TextButton(
          onPressed: () async {
            await action();
            ref.invalidate(locationAccessProvider);
          },
          child: const Text('Fix'),
        ),
      ),
    );
  }
}
