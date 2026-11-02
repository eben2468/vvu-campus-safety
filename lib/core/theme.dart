import 'package:flutter/material.dart';

/// VVU brand colours and SOS colours.
///
/// Brand hex values are approximations of VVU blue and gold — confirm
/// against the university's official brand guide (see DECISIONS.md).
abstract final class AppColors {
  static const vvuBlue = Color(0xFF003A70);
  static const vvuGold = Color(0xFFF2B417);
  static const sosRed = Color(0xFFC62828);
  static const safeGreen = Color(0xFF2E7D32);
}

/// Minimum height for buttons and other tappable controls. Bigger than the
/// Material default (48) so they are easy to hit under stress.
const double kTouchTarget = 56;

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.vvuBlue,
      brightness: brightness,
      secondary: AppColors.vvuGold,
      error: AppColors.sosRed,
    );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const buttonSize = Size(kTouchTarget, kTouchTarget);
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? AppColors.vvuBlue
            : scheme.surface,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}
