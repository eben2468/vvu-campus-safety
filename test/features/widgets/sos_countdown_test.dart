import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/sos/presentation/widgets/sos_countdown_dialog.dart';

/// A button that opens the countdown and remembers what it returned.
class _Host extends StatefulWidget {
  const _Host({required this.seconds});

  final int seconds;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(
            onPressed: () async {
              final send = await showSosCountdown(
                context,
                seconds: widget.seconds,
              );
              setState(() => result = send);
            },
            child: const Text('SOS'),
          ),
          Text('result: $result'),
        ],
      ),
    );
  }
}

Future<void> open(WidgetTester tester, {int seconds = 3}) async {
  await tester.pumpWidget(MaterialApp(home: _Host(seconds: seconds)));
  await tester.tap(find.text('SOS'));
  await tester.pump();
}

void main() {
  testWidgets('counts down and sends when it reaches zero', (tester) async {
    await open(tester);
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('result: true'), findsOneWidget);
  });

  testWidgets('Cancel stops the SOS', (tester) async {
    await open(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('result: false'), findsOneWidget);
    // The timer is gone: nothing is sent later.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('result: false'), findsOneWidget);
  });

  testWidgets('Send now skips the wait', (tester) async {
    await open(tester, seconds: 10);
    await tester.tap(find.text('Send now'));
    await tester.pumpAndSettle();
    expect(find.text('result: true'), findsOneWidget);
  });

  testWidgets('a zero-second countdown sends straight away', (tester) async {
    await open(tester, seconds: 0);
    await tester.pumpAndSettle();
    expect(find.text('result: true'), findsOneWidget);
  });

  testWidgets('stays usable with very large text', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const _Host(seconds: 3),
      ),
    );
    await tester.tap(find.text('SOS'));
    await tester.pump();

    expect(tester.takeException(), isNull); // no overflow
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('result: false'), findsOneWidget);
  });
}
