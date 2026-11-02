import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/functions_service.dart';
import 'data/auth_repository.dart';
import 'data/session.dart';
import 'data/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    functions: ref.watch(functionsProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

/// The signed-in Firebase user. Re-emits on every token refresh.
final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).idTokenChanges();
});

/// Custom claims for the current token.
final tokenClaimsProvider = FutureProvider<TokenClaims?>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).claimsFor(user);
});

/// The signed-in user's `users/{uid}` profile.
final currentProfileProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authUserProvider.select((user) => user.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

/// Combines auth state, claims and profile into one [Session].
final sessionProvider = Provider<Session>((ref) {
  final authUser = ref.watch(authUserProvider);
  if (authUser.hasError) return Session.signedOut;
  if (!authUser.hasValue) return Session.loading;
  final user = authUser.value;
  if (user == null) return Session.signedOut;

  final claims = ref.watch(tokenClaimsProvider).value;
  // A stale value from a previous user counts as still loading.
  if (claims == null || claims.uid != user.uid) return Session.loading;
  if (!claims.canUseApp) return Session.unverified;

  final profile = ref.watch(currentProfileProvider);
  if (profile.isLoading && !profile.hasValue) return Session.loading;
  if (profile.value?.uid case final uid? when uid != user.uid) {
    return Session.loading;
  }
  if (profile.value?.deactivated ?? false) return Session.deactivated;

  return Session(
    status: SessionStatus.active,
    role: claims.role,
    profile: profile.value,
    emailVerified: user.emailVerified,
  );
});

/// A message for the login screen explaining why the user was signed out.
final signOutNoticeProvider = NotifierProvider<SignOutNotice, String?>(
  SignOutNotice.new,
);

class SignOutNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) => state = message;

  void clear() => state = null;
}
