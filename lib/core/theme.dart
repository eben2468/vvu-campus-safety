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

  /// Dark amber for text and lines in the gold family: gold itself is too
  /// light to read on white (WCAG needs 4.5:1 for text).
  static const inProgress = Color(0xFF7A5B00);

  /// Grey that still reads on white (false alarms, closed items).
  static const muted = Color(0xFF616161);

  // Web dashboard surfaces.
  static const navy = Color(0xFF0B2545); // sidebar
  static const canvas = Color(0xFFF3F5F9); // page background
  static const line = Color(0xFFE3E7EF); // card borders, dividers
  static const field = Color(0xFFF7F8FB); // inputs, table headers
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

  /// The web dashboard: used with a mouse on a large screen, so controls
  /// are denser than on the phone, on flat bordered cards over a light
  /// grey canvas.
  static ThemeData dashboard() {
    final base = light();
    final scheme = base.colorScheme.copyWith(
      surface: Colors.white,
      outlineVariant: AppColors.line,
    );
    const radius = BorderRadius.all(Radius.circular(10));
    const buttonShape = RoundedRectangleBorder(borderRadius: radius);
    const buttonSize = Size(40, 44);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    final text = base.textTheme;
    // From the text theme, so button labels keep the app's font family.
    final buttonText = text.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          side: const BorderSide(color: AppColors.line),
          selectedBackgroundColor: AppColors.vvuBlue.withValues(alpha: 0.1),
          selectedForegroundColor: AppColors.vvuBlue,
          textStyle: buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.vvuBlue, 1.5),
        errorBorder: border(AppColors.sosRed),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.field,
          isDense: true,
          border: border(AppColors.line),
          enabledBorder: border(AppColors.line),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.field),
        headingTextStyle: text.labelMedium?.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        dataTextStyle: text.bodyMedium,
        headingRowHeight: 44,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 64,
        horizontalMargin: 20,
        columnSpacing: 28,
        dividerThickness: 1,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 420,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 400),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}
