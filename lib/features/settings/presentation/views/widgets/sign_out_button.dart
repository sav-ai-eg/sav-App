import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';

class SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SignOutButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFFE80000),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppAssets.logoutIcon,
              width: 16.sp,
              height: 16.sp,
              colorFilter: const ColorFilter.mode(
                Color(0xFFE70000),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE70000),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
