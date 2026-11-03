import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/admin/widgets/page_header.dart';
import 'package:vvu_campus_safety/routing/routes.dart';

import 'dashboard_harness.dart';

/// Every dashboard page must open without errors or layout overflows, on a
/// desktop and a small laptop, with data and when everything is empty.
void main() {
  const screens = {'desktop': Size(1440, 900), 'laptop': Size(1024, 700)};

  for (final screen in screens.entries) {
    for (final route in dashboardPages.keys) {
      testWidgets('$route opens on a ${screen.key}', (tester) async {
        await pumpDashboard(tester, route, size: screen.value);
        expect(tester.takeException(), isNull);
        expect(find.byType(PageHeader), findsOneWidget);
        // Labels in the sidebar only when there's room for them.
        expect(
          find.text('VVU Campus Safety'),
          screen.value.width >= 1100 ? findsOneWidget : findsNothing,
        );
      });
    }
  }

  for (final route in dashboardPages.keys) {
    testWidgets('$route shows its empty state', (tester) async {
      await pumpDashboard(tester, route, empty: true);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the sidebar opens each page', (tester) async {
    await pumpDashboard(tester, Routes.dashboard);
    for (final label in ['Incidents', 'Analytics', 'Users', 'ID roster']) {
      await tester.tap(find.text(label).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Download sample CSV'), findsOneWidget);
  });

  testWidgets('pages show their data', (tester) async {
    await pumpDashboard(tester, Routes.dashboardUsers);
    expect(find.text('Samuel Tetteh'), findsOneWidget);
    expect(find.text('On duty'), findsOneWidget);

    await pumpDashboard(tester, Routes.dashboardIncidents);
    expect(find.text('Efia Owusu'), findsWidgets);
    expect(find.text('SOS'), findsWidgets);
  });
}
