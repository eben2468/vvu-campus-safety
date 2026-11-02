import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/app_user.dart';
import 'roster_csv.dart';

/// Which users the users page lists.
enum UserGroup {
  security('Security team', [UserRole.officer, UserRole.admin]),
  students('Students', [UserRole.student]),
  staff('Staff', [UserRole.staff]),
  all('Everyone', UserRole.values);

  const UserGroup(this.label, this.roles);

  final String label;
  final List<UserRole> roles;
}

/// What `adminImportRoster` reported back.
@immutable
class RosterImportResult {
  const RosterImportResult({
    required this.imported,
    required this.rejectedCount,
    required this.rejected,
  });

  final int imported;
  final int rejectedCount;

  /// e.g. "Row 12 (223IT01): Full name is missing." — at most 100 per batch.
  final List<String> rejected;
}

/// User and roster management for admins. Every change goes through an
/// admin Cloud Function, which sets custom claims and writes `auditLogs`.
class AdminRepository {
  AdminRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Largest upload `adminImportRoster` accepts in one call.
  static const rosterBatchSize = 5000;

  /// Users in [group], sorted by name. Capped at 1000; the page's search
  /// box narrows the list further.
  Stream<List<AppUser>> watchUsers(UserGroup group) {
    Query<Map<String, dynamic>> query = _firestore.collection(
      Collections.users,
    );
    if (group != UserGroup.all) {
      query = query.where(
        'role',
        whereIn: [for (final role in group.roles) role.name],
      );
    }
    return query.limit(1000).snapshots().map((snap) {
      final users = [
        for (final doc in snap.docs) AppUser.fromMap(doc.id, doc.data()),
      ];
      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return users;
    });
  }

  /// Creates an officer or admin account with a temporary password.
  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) => _call('adminCreateUser', {
    'email': email,
    'password': password,
    'fullName': fullName,
    'phone': phone,
    'role': role.name,
  });

  Future<void> setRole(String uid, UserRole role) =>
      _call('adminSetRole', {'uid': uid, 'role': role.name});

  /// Deactivating also blocks sign-in and signs the user out of the app.
  Future<void> setDeactivated(String uid, {required bool deactivated}) =>
      _call('adminSetRole', {'uid': uid, 'deactivated': deactivated});

  /// Uploads [rows] in batches of [rosterBatchSize]. Existing IDs are
  /// updated and stay linked to their accounts.
  Future<RosterImportResult> importRoster(List<RosterRow> rows) async {
    var imported = 0;
    var rejectedCount = 0;
    final rejected = <String>[];
    for (var start = 0; start < rows.length; start += rosterBatchSize) {
      final batch = rows.skip(start).take(rosterBatchSize);
      final result = await _call('adminImportRoster', {
        'rows': [for (final row in batch) row.toMap()],
      });
      imported += (result['imported'] as num?)?.toInt() ?? 0;
      rejectedCount += (result['rejectedCount'] as num?)?.toInt() ?? 0;
      for (final item in result['rejected'] as List? ?? const []) {
        final map = Map<String, dynamic>.from(item as Map);
        final row = (map['row'] as num).toInt() + start;
        rejected.add('Row $row (${map['idNumber']}): ${map['reason']}');
      }
    }
    return RosterImportResult(
      imported: imported,
      rejectedCount: rejectedCount,
      rejected: rejected,
    );
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      final value = result.data;
      return value is Map ? Map<String, dynamic>.from(value) : const {};
    } on FirebaseFunctionsException catch (e) {
      throw AppException(switch (e.code) {
        'unavailable' ||
        'deadline-exceeded' => "Can't reach the server. Check your connection.",
        'internal' || 'unknown' => 'Something went wrong. Please try again.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      });
    }
  }
}
