import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

enum PermissionStatus { unknown, allowed, declined, blocked }

/// One permission on the first-run screen: why we need it, and a button to
/// allow it (or open settings if the user blocked it earlier).
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
    required this.status,
    required this.onAsk,
  });

  final IconData icon;
  final String title;
  final String explanation;
  final PermissionStatus status;
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: AppColors.vvuBlue),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: textTheme.titleMedium)),
                if (status == PermissionStatus.allowed)
                  const Icon(Icons.check_circle, color: AppColors.safeGreen),
              ],
            ),
            const SizedBox(height: 8),
            Text(explanation, style: textTheme.bodyMedium),
            if (status == PermissionStatus.declined)
              _note(
                context,
                'Not allowed yet. SOS still works, but security will have to ask where you are.',
              ),
            if (status == PermissionStatus.blocked)
              _note(
                context,
                'Blocked in your phone settings. Open settings to turn it on.',
              ),
            if (status != PermissionStatus.allowed) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onAsk,
                child: Text(
                  status == PermissionStatus.blocked
                      ? 'Open settings'
                      : 'Allow $title',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
