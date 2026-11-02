import 'package:flutter/material.dart';

/// A button that must be held for [holdDuration] before [onConfirmed] runs,
/// so it can't be triggered by an accidental tap. Used for "I'm safe".
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.holdDuration = const Duration(seconds: 2),
  });

  final String label;
  final VoidCallback onConfirmed;
  final Duration holdDuration;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: widget.holdDuration,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onConfirmed();
      _progress.reset();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${widget.label}. Press and hold.',
      onLongPress: widget.onConfirmed,
      child: GestureDetector(
        onTapDown: (_) => _progress.forward(),
        onTapUp: (_) => _progress.reverse(),
        onTapCancel: () => _progress.reverse(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: scheme.surfaceContainerHighest),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress.value,
                    child: ColoredBox(color: scheme.primaryContainer),
                  ),
                ),
                Center(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
