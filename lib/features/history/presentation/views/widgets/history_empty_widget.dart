import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class HistoryEmptyWidget extends StatelessWidget {
  const HistoryEmptyWidget({
    super.key,
    this.message = 'Start a new trip now !',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Error/empty icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 44.sp,
              color: AppColors.whiteColor,
            ),
          ),

          SizedBox(height: 24.h),

          /// Title
          Text(
            "It's a bit empty here",
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),

          SizedBox(height: 14.h),

          /// Subtitle
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
