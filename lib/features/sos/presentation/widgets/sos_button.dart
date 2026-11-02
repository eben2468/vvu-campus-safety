import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

/// The big red SOS button — the dominant element of the home screen.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SOS. Press to alert campus security.',
      child: SizedBox.square(
        dimension: 220,
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: AppColors.sosRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.sosRed.withValues(alpha: 0.6),
            elevation: 8,
          ),
          child: busy
              ? const CircularProgressIndicator(color: Colors.white)
              // Shrinks to fit the circle when the phone uses very large text.
              : const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SOS',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('Press for help', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
