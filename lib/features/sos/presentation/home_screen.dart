import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/widgets/signed_in_scaffold.dart';
import '../../auth/providers.dart';
import '../providers.dart';
import 'active_sos_screen.dart';
import 'widgets/call_security_button.dart';
import 'widgets/location_warning_card.dart';
import 'widgets/sos_button.dart';
import 'widgets/sos_countdown_dialog.dart';

/// Student and staff home: the SOS button. While the user has an open SOS
/// this shows the active SOS screen instead.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sending = false;

  Future<void> _startSos() async {
    final controller = ref.read(sosControllerProvider);
    // Look for a GPS fix while the countdown runs.
    final locationFix = controller.startLocationFix();
    final seconds =
        ref.read(appSettingsProvider).value?.sosCountdownSec ??
        defaultSosCountdownSec;

    if (!await showSosCountdown(context, seconds: seconds)) return;

    setState(() => _sending = true);
    try {
      await controller.send(locationFix);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSos = ref.watch(myActiveSosProvider).value;
    if (activeSos != null) {
      return ActiveSosScreen(key: ValueKey(activeSos.id), incident: activeSos);
    }

    final name = ref.watch(sessionProvider).profile?.firstName;
    final textTheme = Theme.of(context).textTheme;
    return SignedInScaffold(
      title: 'VVU Campus Safety',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const LocationWarningCard(),
            const SizedBox(height: 16),
            Text(
              name == null
                  ? 'Are you in danger?'
                  : 'Hello $name. Are you in danger?',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Press SOS to alert campus security with your location.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Center(
              child: SosButton(onPressed: _startSos, busy: _sending),
            ),
            const SizedBox(height: 32),
            const CallSecurityButton(),
          ],
        ),
      ),
    );
  }
}
