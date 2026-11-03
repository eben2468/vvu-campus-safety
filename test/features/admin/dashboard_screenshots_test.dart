// Saves a PNG of every dashboard page, with sample data and real fonts, to
// check the layout by eye (map tiles stay blank: tests have no network).
// Skipped unless SCREENSHOT_DIR is set:
//
//   $env:SCREENSHOT_DIR = "C:\temp\shots"
//   flutter test test/features/admin/dashboard_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dashboard_harness.dart';

final _outDir = Platform.environment['SCREENSHOT_DIR'];

/// Real Roboto and Material Icons from the Flutter SDK, instead of the
/// block font tests use by default.
Future<void> _loadFonts() async {
  final fonts = Directory(
    '${Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter'}'
    r'\bin\cache\artifacts\material_fonts',
  );
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('${fonts.path}\\$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final weight in ['regular', 'medium', 'bold']) {
    roboto.addFont(read('roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}

void main() {
  testWidgets('screenshots', skip: _outDir == null, (tester) async {
    await tester.runAsync(_loadFonts);
    // flutter_map caches tiles in the app's cache folder; tests have no
    // path_provider plugin, so point it at a temp folder.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    Directory(_outDir!).createSync(recursive: true);

    for (final route in dashboardPages.keys) {
      await pumpDashboard(tester, route);
      final boundary =
          screenshotKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final name = route == '/dashboard'
            ? 'live-board'
            : route.split('/').last;
        await File('$_outDir/$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
      });
    }
  });
}
