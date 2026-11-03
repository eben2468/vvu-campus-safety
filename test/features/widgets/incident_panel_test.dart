import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/admin/incidents/presentation/incident_panel.dart';
import 'package:vvu_campus_safety/features/incidents/providers.dart';

void main() {
  // Regression: the panel's AppBar once sat directly in a Column, failed to
  // lay out, and left only the dark backdrop on screen.
  testWidgets('opens with its header and tabs, and closes', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showIncidentPanel(context, 'missing'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('This incident no longer exists.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsNothing);
  });
}
