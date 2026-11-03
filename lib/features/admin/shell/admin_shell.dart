import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../auth/presentation/widgets/email_verification_banner.dart';
import 'destinations.dart';
import 'new_sos_banner.dart';
import 'sidebar.dart';

/// Frame for every admin dashboard page: the sidebar, a top bar and the
/// new-SOS banner, which shows on whichever page is open.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  /// The current path, to highlight the matching destination.
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final current = destinationFor(location);
    final compact = MediaQuery.sizeOf(context).width < 1100;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sidebar(current: current, compact: compact),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(current: current),
                const EmailVerificationBanner(),
                const NewSosBanner(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where you are, today's date (Accra time is UTC) and a live indicator.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.current});

  final Destination current;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final today = DateFormat('EEEE, d MMMM yyyy')
        .format(DateTime.now().toUtc());
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Text(
            current.group,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ),
          Text(current.label, style: textTheme.titleSmall),
          const Spacer(),
          Text(
            today,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(width: 16),
          const _LiveIndicator(),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'This dashboard updates by itself as things happen.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.safeGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: AppColors.safeGreen),
            SizedBox(width: 6),
            Text(
              'Live',
              style: TextStyle(
                color: AppColors.safeGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
