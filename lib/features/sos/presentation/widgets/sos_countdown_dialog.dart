import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme.dart';

/// Full-screen countdown before an SOS is sent. Returns true to send
/// (countdown finished or "Send now"), false if the user cancelled.
Future<bool> showSosCountdown(
  BuildContext context, {
  required int seconds,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    pageBuilder: (_, _, _) => _SosCountdown(seconds: seconds),
  );
  return result ?? false;
}

class _SosCountdown extends StatefulWidget {
  const _SosCountdown({required this.seconds});

  final int seconds;

  @override
  State<_SosCountdown> createState() => _SosCountdownState();
}

class _SosCountdownState extends State<_SosCountdown> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_remaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish(true));
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _finish(true);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _finish(bool send) {
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop(send);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.sosRed,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Sending SOS in',
                style: textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              // Already huge; it isn't scaled further so it fits small phones.
              Text(
                '$_remaining',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                semanticsLabel: '$_remaining seconds',
              ),
              const Spacer(),
              // At least 72 high, taller if the phone uses large text.
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.sosRed,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _finish(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => _finish(true),
                child: const Text('Send now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
