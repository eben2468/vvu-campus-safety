import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/officer/presentation/widgets/action_dialogs.dart';

Future<String?> Function() _open(WidgetTester tester, {bool required = false}) {
  String? result;
  var done = false;
  return () async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await askForNote(
                  context,
                  title: 'Resolve',
                  hint: 'What was done?',
                  confirmLabel: 'Resolve',
                  required: required,
                );
                done = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Escorted to hostel ');
    await tester.tap(find.widgetWithText(FilledButton, 'Resolve'));
    // Let the closing animation run: the controller must still be alive.
    await tester.pumpAndSettle();
    expect(done, isTrue);
    return result;
  };
}

void main() {
  // Regression: the controller was disposed when the dialog's future
  // completed, while the closing animation still rebuilt the text field.
  testWidgets('returns the trimmed note and closes cleanly', (tester) async {
    final result = await _open(tester)();
    expect(tester.takeException(), isNull);
    expect(result, 'Escorted to hostel');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a required note cannot be left blank', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => askForNote(
                context,
                title: 'False alarm',
                hint: 'Why?',
                confirmLabel: 'Mark as false alarm',
                required: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark as false alarm'));
    await tester.pump();
    expect(find.text('Write a note first.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
