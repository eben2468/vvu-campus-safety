import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../auth/providers.dart';
import '../widgets/status_views.dart';
import 'destinations.dart';

/// The dark navigation column: brand, grouped pages and the signed-in
/// admin. [compact] shows icons only, for narrower windows.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key, required this.current, required this.compact});

  final Destination current;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref.watch(sessionProvider.select((s) => s.profile?.fullName)) ?? '';

    // Each group starts with its label (or, when compact, a small gap).
    final items = <Widget>[];
    String? group;
    for (final d in destinations) {
      if (d.group != group) {
        if (compact) {
          if (group != null) items.add(const SizedBox(height: 16));
        } else {
          items.add(_GroupLabel(d.group));
        }
        group = d.group;
      }
      items.add(
        _NavItem(destination: d, selected: d == current, compact: compact),
      );
    }

    return Container(
      width: compact ? 76 : 252,
      color: AppColors.navy,
      child: Column(
        children: [
          _Brand(compact: compact),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: items,
            ),
          ),
          _Account(name: name, compact: compact),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 18 : 20, 22, 16, 18),
      child: Row(
        children: [
          const AppLogo(size: 40),
          if (!compact) ...[
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VVU Campus Safety',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Security dashboard',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.compact,
  });

  final Destination destination;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    final item = Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        onTap: () => context.go(destination.route),
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.vvuGold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(destination.icon, color: color, size: 22),
              if (!compact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: compact ? Tooltip(message: destination.label, child: item) : item,
    );
  }
}

class _Account extends ConsumerWidget {
  const _Account({required this.name, required this.compact});

  final String name;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signOut = IconButton(
      tooltip: 'Sign out',
      onPressed: () => ref.read(signOutProvider)(),
      icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
    );
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.all(compact ? 4 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: compact
          ? signOut
          : Row(
              children: [
                InitialsAvatar(
                  name.isEmpty ? 'Admin' : name,
                  background: AppColors.vvuGold,
                  foreground: AppColors.navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Administrator' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Administrator',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                signOut,
              ],
            ),
    );
  }
}
