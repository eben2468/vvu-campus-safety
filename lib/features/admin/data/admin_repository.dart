import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../models/app_settings.dart';
import '../../../models/app_user.dart';
import '../../../models/roster_entry.dart';
import '../../../services/api_client.dart';
import 'roster_csv.dart';

/// A point as the admin functions expect it.
typedef LatLngMap = Map<String, double>;

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
/// admin API call, which sets custom claims and writes `auditLogs`.
class AdminRepository {
  AdminRepository(this._firestore, this._api);

  final FirebaseFirestore _firestore;
  final ApiClient _api;

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

  /// Most roster entries the roster page loads. Each one opened costs a
  /// Firestore read, and the free plan allows 50,000 a day.
  static const rosterViewLimit = 2000;

  /// Imported IDs, sorted by name. Updates live as people register.
  Stream<List<RosterEntry>> watchRoster() {
    return _firestore
        .collection(Collections.idRoster)
        .limit(rosterViewLimit)
        .snapshots()
        .map((snap) {
          final entries = [
            for (final doc in snap.docs)
              RosterEntry.fromMap(doc.id, doc.data()),
          ];
          entries.sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
          return entries;
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

  /// Saves `settings/app` through `adminUpdateSettings`, which validates it
  /// and writes the audit log. Returns the names of the fields that changed.
  Future<List<String>> updateSettings(AppSettings settings) async {
    LatLngMap point(GeoPoint p) => {'lat': p.latitude, 'lng': p.longitude};
    final result = await _call('adminUpdateSettings', {
      'categories': settings.categories,
      'securityPhone': settings.securityPhone,
      'sosCountdownSec': settings.sosCountdownSec,
      'campusBoundary': [for (final p in settings.campusBoundary) point(p)],
      'zones': [
        for (final z in settings.zones)
          {'name': z.name, 'center': point(z.center), 'radiusM': z.radiusM},
      ],
    });
    return List<String>.from(result['changed'] as List? ?? const []);
  }

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
      return await _api.call(name, data);
    } on ApiException catch (e) {
      throw AppException(switch (e.code) {
        'unavailable' => "Can't reach the server. Check your connection.",
        'internal' => 'Something went wrong. Please try again.',
        _ => e.message,
      });
    }
  }
}
