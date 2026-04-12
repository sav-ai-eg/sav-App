import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

/// A status badge chip showing label with icon and color.
class StatusBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showRefresh;

  const StatusBadge({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.onTap,
    this.showRefresh = false,
  });

  /// Factory for "AI Ready" badge.
  factory StatusBadge.aiReady({bool isReady = true}) {
    return StatusBadge(
      text: isReady ? 'AI Ready' : 'AI Loading...',
      icon: isReady ? Icons.psychology_rounded : Icons.sync_rounded,
      color: isReady ? AppColors.successColor : AppColors.grayColor,
    );
  }

  /// Factory for "Offline" badge with sync count.
  factory StatusBadge.offline({int pendingCount = 0}) {
    return StatusBadge(
      text: pendingCount > 0 ? 'Offline ($pendingCount pending)' : 'Offline',
      icon: Icons.cloud_off_rounded,
      color: AppColors.warningColor,
    );
  }

  /// Factory for "Online" badge.
  factory StatusBadge.online() {
    return const StatusBadge(
      text: 'Online',
      icon: Icons.cloud_done_rounded,
      color: AppColors.successColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 6.w),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (showRefresh) ...[
              SizedBox(width: 4.w),
              Icon(Icons.refresh_rounded, size: 12.sp, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
