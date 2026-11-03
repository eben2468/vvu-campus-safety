import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// A white card with a header (icon, title, optional subtitle and trailing
/// widget) above its content.
///
/// With [expand], the content fills the card's height; use it when the card
/// itself is given a height (e.g. inside an Expanded).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.trailing,
    this.expand = false,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final bool expand;

  /// Padding around [child]; zero for edge-to-edge lists and tables.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            IconBadge(icon: icon!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    final body = Padding(padding: padding, child: child);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (expand) Expanded(child: body) else body,
        ],
      ),
    );
  }
}

/// An icon on a softly tinted rounded square.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.vvuBlue,
    this.size = 34,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
