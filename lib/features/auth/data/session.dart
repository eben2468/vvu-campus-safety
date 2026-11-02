import '../../../core/constants.dart';
import '../../../models/app_user.dart';

/// The claims from the Firebase ID token that the app uses.
class TokenClaims {
  const TokenClaims({required this.uid, this.role, this.verified = false});

  factory TokenClaims.fromMap(String uid, Map<String, dynamic>? claims) {
    return TokenClaims(
      uid: uid,
      role: UserRole.fromValue(claims?['role'] as String?),
      verified: claims?['verified'] == true,
    );
  }

  final String uid;
  final UserRole? role;
  final bool verified;

  /// Students and staff need a verified ID; officers and admins are created
  /// by an admin and only need a role.
  bool get canUseApp => role != null && (verified || role!.isOfficer);
}

enum SessionStatus {
  /// Still working out who is signed in.
  loading,
  signedOut,

  /// Signed in, but the account is not linked to a VVU ID yet.
  unverified,

  /// Blocked by an admin; the app signs out straight away.
  deactivated,
  active,
}

/// Who is using the app right now. The router redirects from this.
class Session {
  const Session({
    required this.status,
    this.role,
    this.profile,
    this.emailVerified = false,
  });

  static const loading = Session(status: SessionStatus.loading);
  static const signedOut = Session(status: SessionStatus.signedOut);
  static const unverified = Session(status: SessionStatus.unverified);
  static const deactivated = Session(status: SessionStatus.deactivated);

  final SessionStatus status;

  /// From the custom claim; set when [status] is [SessionStatus.active].
  final UserRole? role;
  final AppUser? profile;
  final bool emailVerified;
}
