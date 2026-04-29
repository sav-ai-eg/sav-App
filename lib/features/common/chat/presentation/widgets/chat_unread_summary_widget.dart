import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class ChatUnreadSummaryWidget extends StatelessWidget {
  final int totalUnreadMessages;
  final int conversationsWithUnread;
  final VoidCallback? onTap;

  const ChatUnreadSummaryWidget({
    super.key,
    required this.totalUnreadMessages,
    required this.conversationsWithUnread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalUnreadMessages == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications,
              color: AppColors.whiteColor,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalUnreadMessages unread message${totalUnreadMessages == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  if (conversationsWithUnread > 1)
                    Text(
                      'in $conversationsWithUnread conversation${conversationsWithUnread == 1 ? '' : 's'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.whiteColor.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.whiteColor,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}