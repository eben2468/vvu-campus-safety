import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/errors/app_exception.dart';
import 'package:vvu_campus_safety/features/auth/data/auth_repository.dart';
import 'package:vvu_campus_safety/features/auth/presentation/register_screen.dart';
import 'package:vvu_campus_safety/features/auth/providers.dart';

/// Records what the screen sends instead of calling Firebase.
class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({this.error});

  final String? error;
  Map<String, String>? registered;

  @override
  Future<void> register({
    required String fullName,
    required String idNumber,
    required String email,
    required String phone,
    required String password,
  }) async {
    registered = {
      'fullName': fullName,
      'idNumber': idNumber,
      'email': email,
      'phone': phone,
    };
    if (error != null) throw AppException(error!);
  }
}

Future<FakeAuthRepository> pumpRegister(
  WidgetTester tester, {
  String? error,
}) async {
  final auth = FakeAuthRepository(error: error);
  tester.view.physicalSize = const Size(1080, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: const MaterialApp(home: RegisterScreen()),
    ),
  );
  return auth;
}

Future<void> fill(WidgetTester tester, String label, String text) =>
    tester.enterText(find.widgetWithText(TextFormField, label), text);

Future<void> submit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Create account');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('shows every problem and sends nothing when empty', (
    tester,
  ) async {
    final auth = await pumpRegister(tester);
    await submit(tester);

    expect(
      find.text('Enter your full name as on your VVU ID.'),
      findsOneWidget,
    );
    expect(find.text('Enter your VVU ID number.'), findsOneWidget);
    expect(find.text('Enter your phone number.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(auth.registered, isNull);
  });

  testWidgets('normalises the ID and phone before registering', (tester) async {
    final auth = await pumpRegister(tester);
    await fill(tester, 'Full name', 'Kwame Mensah');
    await fill(tester, 'VVU ID number', '223it 0100001');
    await fill(tester, 'Phone number', '024 123 4567');
    await fill(tester, 'Email', 'kwame@example.com');
    await fill(tester, 'Password', 'password123');
    await fill(tester, 'Confirm password', 'password123');
    await submit(tester);

    expect(auth.registered, {
      'fullName': 'Kwame Mensah',
      'idNumber': '223IT0100001',
      'email': 'kwame@example.com',
      'phone': '+233241234567',
    });
  });

  testWidgets('shows the reason when the ID is rejected', (tester) async {
    await pumpRegister(
      tester,
      error: 'ID not found — contact the Security Office.',
    );
    await fill(tester, 'Full name', 'Fake Person');
    await fill(tester, 'VVU ID number', '999XX0000000');
    await fill(tester, 'Phone number', '0241234567');
    await fill(tester, 'Email', 'fake@example.com');
    await fill(tester, 'Password', 'password123');
    await fill(tester, 'Confirm password', 'password123');
    await submit(tester);
    await tester.pump();

    expect(
      find.text('ID not found — contact the Security Office.'),
      findsOneWidget,
    );
  });

  testWidgets('passwords must match', (tester) async {
    await pumpRegister(tester);
    await fill(tester, 'Password', 'password123');
    await fill(tester, 'Confirm password', 'password124');
    await submit(tester);
    expect(find.textContaining('match'), findsOneWidget);
  });
}
