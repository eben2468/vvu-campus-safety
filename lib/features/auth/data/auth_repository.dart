import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import 'session.dart';

const accountDeactivatedMessage =
    'This account has been deactivated. Contact the Security Office.';

/// Sign-in, registration and ID verification. Firebase errors are turned
/// into [AppException]s with plain-English messages.
class AuthRepository {
  AuthRepository({required this._auth, required this._functions});

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  /// Emits on sign-in, sign-out and every token refresh (which is when new
  /// custom claims arrive).
  Stream<User?> idTokenChanges() => _auth.idTokenChanges();

  Future<TokenClaims> claimsFor(User user) async {
    final token = await user.getIdTokenResult();
    return TokenClaims.fromMap(user.uid, token.claims);
  }

  Future<void> signIn({required String email, required String password}) {
    return _guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  /// Creates the account, then links it to the VVU ID. If the ID check fails
  /// the new account is deleted so it can't be used, and the error rethrown.
  Future<void> register({
    required String fullName,
    required String idNumber,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
    final user = credential.user!;
    try {
      await verifyId(idNumber: idNumber, fullName: fullName, phone: phone);
    } on AppException {
      try {
        await user.delete();
      } on FirebaseAuthException {
        // Still signed in but unverified: the router shows the verify-ID screen.
      }
      rethrow;
    }
    // Best effort: the email banner offers a resend if this fails.
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException {
      // ignore
    }
  }

  /// Calls the `verifyId` function, then refreshes the token so the new
  /// `role` claim reaches the app.
  Future<void> verifyId({
    required String idNumber,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _functions.httpsCallable('verifyId').call<Object?>({
        'idNumber': idNumber,
        'fullName': fullName,
        'phone': phone,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AppException(_functionsMessage(e));
    }
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // Don't reveal whether an account exists.
      if (e.code == 'user-not-found') return;
      throw AppException(_authMessage(e.code));
    }
  }

  Future<void> resendVerificationEmail() {
    return _guard(() async => _auth.currentUser?.sendEmailVerification());
  }

  /// Reloads the user (e.g. after they click the email link) and refreshes
  /// the token so [idTokenChanges] emits the updated user.
  Future<void> refreshUser() {
    return _guard(() async {
      await _auth.currentUser?.reload();
      await _auth.currentUser?.getIdToken(true);
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AppException(_authMessage(e.code));
    }
  }

  static String _authMessage(String code) => switch (code) {
    'invalid-email' => 'That email address is not valid.',
    'user-disabled' => accountDeactivatedMessage,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'email-already-in-use' =>
      'An account with this email already exists. Log in instead.',
    'weak-password' => 'Choose a stronger password (at least 8 characters).',
    'too-many-requests' =>
      'Too many attempts. Wait a few minutes and try again.',
    'network-request-failed' =>
      'No internet connection. Check your data or Wi-Fi and try again.',
    _ => 'Something went wrong. Please try again.',
  };

  static String _functionsMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
      case 'failed-precondition':
      case 'permission-denied':
      case 'already-exists':
      case 'invalid-argument':
      case 'unauthenticated':
        return e.message ?? 'We could not verify your ID.';
      case 'unavailable':
      case 'deadline-exceeded':
        return "Can't reach the server. Check your connection and try again.";
      default:
        return 'Something went wrong verifying your ID. Please try again.';
    }
  }
}
