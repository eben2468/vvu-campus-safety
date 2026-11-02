import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/location_service.dart';
import '../../../services/messaging_service.dart';
import '../../../services/preferences_service.dart';
import '../../sos/providers.dart';
import '../providers.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/permission_tile.dart';

/// First-run screen on a phone: explains why the app needs location and
/// notifications, then asks. Declining never blocks the app — SOS still
/// works, and the home screen offers to ask again.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool? _notificationsAllowed;

  Future<void> _askLocation(LocationAccess current) async {
    final service = ref.read(locationServiceProvider);
    switch (current) {
      case LocationAccess.deniedForever:
        await service.openAppSettings();
      case LocationAccess.serviceOff:
        await service.openLocationSettings();
      case LocationAccess.denied || LocationAccess.granted:
        await service.requestAccess();
    }
    ref.invalidate(locationAccessProvider);
  }

  Future<void> _askNotifications() async {
    final allowed = await ref
        .read(messagingServiceProvider)
        .requestPermission();
    if (mounted) setState(() => _notificationsAllowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    final isOfficer = ref.watch(sessionProvider).role?.isOfficer ?? false;
    final location = ref.watch(locationAccessProvider).value;

    return AuthScaffold(
      title: 'Before you start',
      subtitle: 'Two permissions help security reach you fast.',
      children: [
        if (!isOfficer) ...[
          PermissionTile(
            icon: Icons.my_location,
            title: 'Location',
            explanation:
                'Lets security see where you are when you press SOS. '
                'Your location is only shared while an SOS is active.',
            status: switch (location) {
              LocationAccess.granted => PermissionStatus.allowed,
              LocationAccess.deniedForever ||
              LocationAccess.serviceOff => PermissionStatus.blocked,
              LocationAccess.denied => PermissionStatus.declined,
              null => PermissionStatus.unknown,
            },
            onAsk: location == null ? null : () => _askLocation(location),
          ),
          const SizedBox(height: 12),
        ],
        PermissionTile(
          icon: Icons.notifications_active,
          title: 'Notifications',
          explanation: isOfficer
              ? 'Alerts you the moment someone presses SOS or reports an incident.'
              : 'Tells you when an officer is on the way and shares campus safety alerts.',
          status: switch (_notificationsAllowed) {
            true => PermissionStatus.allowed,
            false => PermissionStatus.declined,
            null => PermissionStatus.unknown,
          },
          onAsk: _askNotifications,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => ref.read(onboardingDoneProvider.notifier).markDone(),
          child: const Text('Continue'),
        ),
        const SizedBox(height: 8),
        Text(
          'You can change these later in your phone settings.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
