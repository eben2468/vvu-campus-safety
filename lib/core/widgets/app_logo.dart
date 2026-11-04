import 'package:flutter/material.dart';

/// The app icon, with the same rounded corners at any [size].
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.23),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        semanticLabel: 'VVU Campus Safety',
      ),
    );
  }
}
