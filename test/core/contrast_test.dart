import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/theme.dart';
import 'package:vvu_campus_safety/features/incidents/presentation/widgets/status_chip.dart';
import 'package:vvu_campus_safety/features/sos/presentation/widgets/sos_button.dart';
import 'package:vvu_campus_safety/models/incident_status.dart';

/// WCAG 2.1 contrast ratio between two opaque colours (1 to 21).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// [color] at [alpha] painted over white, as the status chip does.
Color tintOnWhite(Color color, double alpha) =>
    Color.alphaBlend(color.withValues(alpha: alpha), Colors.white);

void main() {
  group('colour contrast (WCAG AA: 4.5:1 for text)', () {
    test('white text on the app bar, SOS and success colours', () {
      expect(contrast(Colors.white, AppColors.vvuBlue), greaterThan(4.5));
      expect(contrast(Colors.white, AppColors.sosRed), greaterThan(4.5));
      expect(contrast(Colors.white, AppColors.safeGreen), greaterThan(4.5));
    });

    test('every status chip is readable', () {
      for (final status in IncidentStatus.values) {
        final color = StatusChip.colorFor(status);
        expect(
          contrast(color, tintOnWhite(color, 0.06)),
          greaterThan(4.5),
          reason: status.label,
        );
      }
    });

    test('VVU gold is only used where text is not drawn on white', () {
      // Gold on white is too faint for text, hence AppColors.inProgress.
      expect(contrast(AppColors.vvuGold, Colors.white), lessThan(3));
      expect(contrast(AppColors.inProgress, Colors.white), greaterThan(4.5));
    });
  });

  testWidgets('the SOS button fits its circle with 200% text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(child: SosButton(onPressed: () {})),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('SOS'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('SOS. Press to alert')),
      findsOneWidget,
    );
  });
}
