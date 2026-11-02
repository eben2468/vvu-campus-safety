import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/launchers.dart';
import '../../providers.dart';

/// Dials the Security Office number from `settings/app.securityPhone`.
/// Hidden until the number is set.
class CallSecurityButton extends ConsumerWidget {
  const CallSecurityButton({super.key, this.filled = false});

  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(appSettingsProvider).value?.securityPhone ?? '';
    if (phone.isEmpty) return const SizedBox.shrink();

    final icon = const Icon(Icons.call);
    const label = Text('Call security');
    void onPressed() => callNumber(phone);
    return filled
        ? FilledButton.icon(onPressed: onPressed, icon: icon, label: label)
        : OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}
