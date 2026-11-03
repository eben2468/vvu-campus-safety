import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vvu_campus_safety/features/auth/data/auth_repository.dart';

void main() {
  group('isAccountGone', () {
    test('recognises deleted or disabled accounts by code', () {
      for (final code in ['user-not-found', 'user-disabled']) {
        expect(isAccountGone(FirebaseAuthException(code: code)), isTrue);
      }
    });

    test('recognises the server reason Android reports as unknown', () {
      // Seen on a phone after the account was deleted.
      final error = FirebaseAuthException(
        code: 'unknown',
        message: 'An internal error has occurred. [ INVALID_REFRESH_TOKEN ]',
      );
      expect(isAccountGone(error), isTrue);
    });

    test('does not sign out for network trouble or other errors', () {
      expect(
        isAccountGone(FirebaseAuthException(code: 'network-request-failed')),
        isFalse,
      );
      expect(isAccountGone(FirebaseAuthException(code: 'unknown')), isFalse);
      expect(isAccountGone(Exception('offline')), isFalse);
      expect(isAccountGone(null), isFalse);
    });
  });
}
