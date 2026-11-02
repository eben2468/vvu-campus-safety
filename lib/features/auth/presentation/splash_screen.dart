import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/env.dart';
import '../../../core/theme.dart';

/// Shown while the app works out who is signed in. The router then
/// redirects to login or the user's home screen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.vvuBlue,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, size: 96, color: AppColors.vvuGold),
                const SizedBox(height: 16),
                Text(
                  'VVU Campus Safety',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Valley View University, Oyibi',
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: AppColors.vvuGold),
                if (useEmulator) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Local emulators (${Firebase.app().options.projectId})',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
