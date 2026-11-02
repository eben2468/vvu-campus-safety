import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/core/utils/formatters.dart';
import 'package:vvu_campus_safety/core/utils/validators.dart';

void main() {
  group('normalizeGhanaPhone', () {
    test('accepts common ways of writing a Ghana number', () {
      for (final input in [
        '024 123 4567',
        '0241234567',
        '241234567',
        '233241234567',
        '+233 24 123 4567',
        '024-123-4567',
      ]) {
        expect(normalizeGhanaPhone(input), '+233241234567', reason: input);
      }
    });

    test('rejects numbers that are not Ghanaian or are the wrong length', () {
      expect(normalizeGhanaPhone('+44 7700 900123'), isNull);
      expect(normalizeGhanaPhone('02412345'), isNull);
      expect(normalizeGhanaPhone('phone'), isNull);
    });
  });

  test('normalizeIdNumber uppercases and strips spaces', () {
    expect(normalizeIdNumber(' 223it 0100946 '), '223IT0100946');
  });

  test('validators accept good input', () {
    expect(Validators.email('kwame@example.com'), isNull);
    expect(Validators.password('12345678'), isNull);
    expect(Validators.fullName('Kwame Mensah'), isNull);
    expect(Validators.idNumber('223it0100946'), isNull);
    expect(Validators.ghanaPhone('024 123 4567'), isNull);
  });

  test('validators reject bad input', () {
    expect(Validators.email('kwame@'), isNotNull);
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.fullName('Kwame'), isNotNull);
    expect(Validators.idNumber('223/IT'), isNotNull);
    expect(Validators.ghanaPhone('12345'), isNotNull);
  });

  test('confirmPassword compares with the original field', () {
    final validate = Validators.confirmPassword(() => 'secret123');
    expect(validate('secret123'), isNull);
    expect(validate('secret124'), isNotNull);
  });

  test('report descriptions must be 10 to 1000 characters', () {
    expect(Validators.reportDescription('Too short'), isNotNull);
    expect(Validators.reportDescription('   padded       '), isNotNull);
    expect(
      Validators.reportDescription('Laptop stolen in the library'),
      isNull,
    );
    expect(Validators.reportDescription('x' * 1001), isNotNull);
  });
}
