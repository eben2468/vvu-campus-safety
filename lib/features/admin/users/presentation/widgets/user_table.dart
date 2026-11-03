import 'package:flutter/material.dart';

import '../../../../../core/constants.dart';
import '../../../../../core/theme.dart';
import '../../../../../models/app_user.dart';
import '../../../widgets/status_views.dart';
import 'user_actions.dart';

/// Users as table rows, with each user's actions in the last column.
class UserTable extends StatelessWidget {
  const UserTable({super.key, required this.users, required this.myUid});

  final List<AppUser> users;

  /// The signed-in admin, who can't change their own account.
  final String? myUid;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('NAME')),
                DataColumn(label: Text('PHONE')),
                DataColumn(label: Text('ROLE')),
                DataColumn(label: Text('VVU ID')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('')),
              ],
              rows: [for (final user in users) _row(context, user)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, AppUser user) {
    final textTheme = Theme.of(context).textTheme;
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InitialsAvatar(user.fullName, radius: 16),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: textTheme.titleSmall),
                  Text(
                    user.email,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(Text(user.phone)),
        DataCell(Pill(roleLabel(user.role), color: _roleColor(user.role))),
        DataCell(Text(user.idNumber ?? '—')),
        DataCell(_status(user)),
        DataCell(
          // Admins can't change their own account (adminSetRole).
          user.uid == myUid
              ? const Pill('You', color: AppColors.vvuBlue)
              : UserActions(user: user),
        ),
      ],
    );
  }

  static Color _roleColor(UserRole? role) => switch (role) {
    UserRole.admin => AppColors.navy,
    UserRole.officer => AppColors.inProgress,
    _ => AppColors.vvuBlue,
  };

  static Widget _status(AppUser user) {
    if (user.deactivated) {
      return const Pill(
        'Deactivated',
        color: AppColors.sosRed,
        icon: Icons.block,
      );
    }
    if (user.onDuty) {
      return const Pill(
        'On duty',
        color: AppColors.safeGreen,
        icon: Icons.shield,
      );
    }
    if (user.falseAlarmCount > 0) {
      final n = user.falseAlarmCount;
      return Pill(
        '$n false alarm${n == 1 ? '' : 's'}',
        color: AppColors.inProgress,
        icon: Icons.do_not_disturb,
      );
    }
    return const Pill('Active', color: AppColors.safeGreen);
  }
}
