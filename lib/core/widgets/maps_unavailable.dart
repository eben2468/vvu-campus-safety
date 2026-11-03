import 'package:flutter/material.dart';

/// Shown in place of a map when Google Maps isn't loaded (no web Maps key
/// yet), so the rest of the page keeps working.
class MapsUnavailable extends StatelessWidget {
  const MapsUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Map not available: no Google Maps key is set up for the '
            'dashboard yet. Everything else on this page still works.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
