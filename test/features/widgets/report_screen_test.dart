import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:vvu_campus_safety/core/errors/app_exception.dart';
import 'package:vvu_campus_safety/features/incidents/presentation/report_screen.dart';
import 'package:vvu_campus_safety/features/incidents/providers.dart';
import 'package:vvu_campus_safety/features/sos/providers.dart';
import 'package:vvu_campus_safety/models/app_settings.dart';
import 'package:vvu_campus_safety/routing/routes.dart';
import 'package:vvu_campus_safety/services/location_service.dart';

class FakeLocationService extends Fake implements LocationService {
  @override
  Future<Position?> currentPosition({Duration? timeout}) async => null;
}

class FakeReportController extends Fake implements ReportController {
  FakeReportController({this.error});

  final String? error;
  String? category;
  String? description;

  @override
  Future<String> submit({
    required String category,
    required String description,
    required List<Uint8List> photos,
    GeoPoint? location,
  }) async {
    this.category = category;
    this.description = description;
    if (error != null) throw AppException(error!);
    return 'new-id';
  }
}

Future<FakeReportController> pumpReport(
  WidgetTester tester, {
  String? error,
  // 360 dp wide like a small phone, tall enough for the whole form.
  Size screen = const Size(1080, 4200),
}) async {
  final controller = FakeReportController(error: error);
  tester.view.physicalSize = screen;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportControllerProvider.overrideWithValue(controller),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        appSettingsProvider.overrideWith(
          (ref) =>
              Stream.value(const AppSettings(categories: ['Theft', 'Medical'])),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: Routes.report,
          routes: [
            GoRoute(
              path: Routes.report,
              builder: (_, _) => const ReportScreen(),
            ),
            GoRoute(
              path: Routes.reportDetailPattern,
              builder: (_, state) =>
                  Text('Report ${state.pathParameters['incidentId']}'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

Future<void> send(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Send report');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

Future<void> chooseCategory(WidgetTester tester, String category) async {
  await tester.tap(find.text('What happened?'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(category).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('needs a category and a real description', (tester) async {
    final controller = await pumpReport(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'short',
    );
    await send(tester);

    expect(find.text('Choose a category.'), findsOneWidget);
    expect(find.textContaining('at least 10 characters'), findsOneWidget);
    expect(controller.category, isNull);
  });

  testWidgets('sends the category and description from settings', (
    tester,
  ) async {
    final controller = await pumpReport(tester);
    await chooseCategory(tester, 'Medical');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'A student fainted outside the library.',
    );
    await send(tester);

    expect(controller.category, 'Medical');
    expect(controller.description, 'A student fainted outside the library.');
    await tester.pumpAndSettle();
    expect(find.text('Report new-id'), findsOneWidget); // opens the report
  });

  // Regression: on a real phone the category field scrolled out of view,
  // a ListView dropped it, validation skipped it and sending crashed.
  testWidgets('a scrolled-away category is still required', (tester) async {
    final controller = await pumpReport(
      tester,
      screen: const Size(1080, 2340), // 360 x 780 dp
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'My phone was taken in the library.',
    );
    await send(tester); // scrolls down to the button first

    expect(tester.takeException(), isNull);
    expect(controller.category, isNull);
    expect(
      find.text('Choose what happened and describe it, then send.'),
      findsOneWidget,
    );
  });

  testWidgets('shows why a report could not be sent', (tester) async {
    await pumpReport(tester, error: 'No connection. Try again.');
    await chooseCategory(tester, 'Theft');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'My bag was taken from the hall.',
    );
    await send(tester);
    await tester.pump();

    expect(find.text('No connection. Try again.'), findsOneWidget);
  });
}
