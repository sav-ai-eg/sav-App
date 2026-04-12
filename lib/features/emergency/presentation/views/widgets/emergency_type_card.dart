import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class EmergencyTypeCard extends StatelessWidget {
  final String svgAsset;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const EmergencyTypeCard({
    super.key,
    required this.svgAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 48.w) / 2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: cardWidth,
        height: 174.h,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20.r),
          border: isSelected
              ? Border.all(color: AppColors.whiteColor, width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// SVG Icon
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: SvgPicture.asset(
                svgAsset,
                width: 80.w,
                height: 80.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.whiteColor,
                  BlendMode.srcIn,
                ),
              ),
            ),

            SizedBox(height: 12.h),

            /// Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
