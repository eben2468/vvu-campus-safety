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
    await tester.tap(find.text('Import a file'));
    await tester.pump(const Duration(milliseconds: 300));
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

  testWidgets('the roster lists imported IDs', (tester) async {
    await pumpDashboard(tester, Routes.dashboardRoster);
    expect(find.text('Imported IDs (62)'), findsOneWidget);
    expect(find.text('223IT0100001'), findsOneWidget);
    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('1–50 of 62'), findsOneWidget);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pump();
    expect(find.text('51–62 of 62'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '224ba');
    await tester.pump();
    expect(find.text('Kofi Asante'), findsOneWidget);
    expect(find.text('1–1 of 1'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'nobody');
    await tester.pump();
    expect(find.text('No IDs match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the users page links to the roster', (tester) async {
    await pumpDashboard(tester, Routes.dashboardUsers);
    await tester.tap(find.text('View ID roster'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Imported IDs (62)'), findsOneWidget);
  });
}
