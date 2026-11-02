import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/theme.dart';

void main() {
  testWidgets('filled buttons meet the large touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: FilledButton(onPressed: () {}, child: const Text('Send')),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(kTouchTarget));
  });
}
