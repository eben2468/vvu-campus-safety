import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Shown instead of a list or table that has nothing in it, or failed to
/// load.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.isError = false,
  });

  /// A load failure, worded the same way everywhere.
  const EmptyState.error(String what, {super.key})
    : icon = Icons.cloud_off,
      title = 'Could not load $what',
      message = 'Check the connection and refresh the page.',
      isError = true;

  final IconData icon;
  final String title;
  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = isError ? AppColors.sosRed : AppColors.vvuBlue;
    // Scrollable so a short card never overflows; it doesn't move otherwise.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small tinted label, e.g. a role, type or status.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = AppColors.muted, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A round avatar with a person's initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(
    this.name, {
    super.key,
    this.radius = 18,
    this.background,
    this.foreground = AppColors.vvuBlue,
  });

  final String name;
  final double radius;
  final Color? background;
  final Color foreground;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = [for (final p in parts.take(2)) p[0].toUpperCase()];
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? foreground.withValues(alpha: 0.1),
      foregroundColor: foreground,
      child: Text(
        initialsOf(name),
        style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w700),
      ),
    );
  }
}
