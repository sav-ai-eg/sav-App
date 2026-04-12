import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

abstract class AppTextStyles {
  static TextStyle textStyle32 = GoogleFonts.inter(
    fontSize: AppFonts.t32,
    fontWeight: FontWeight.w700,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle28 = GoogleFonts.inter(
    fontSize: AppFonts.t28,
    fontWeight: FontWeight.w700,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle24 = GoogleFonts.inter(
    fontSize: AppFonts.t24,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  static TextStyle textStyle20 = GoogleFonts.inter(
    fontSize: AppFonts.t20,
    fontWeight: FontWeight.w600,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle18 = GoogleFonts.inter(
    fontSize: AppFonts.t18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryColor,
  );

  static TextStyle textStyle16 = GoogleFonts.inter(
    fontSize: AppFonts.t16,
    fontWeight: FontWeight.w400,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle14 = GoogleFonts.inter(
    fontSize: AppFonts.t14,
    fontWeight: FontWeight.w400,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle12 = GoogleFonts.inter(
    fontSize: AppFonts.t12,
    fontWeight: FontWeight.w400,
    color: AppColors.blackColor,
  );

  static TextStyle textStyle10 = GoogleFonts.inter(
    fontSize: AppFonts.t10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryColor,
  );

  static TextStyle textStyle8 = GoogleFonts.inter(
    fontSize: AppFonts.t8,
    fontWeight: FontWeight.w400,
    color: AppColors.blackColor,
  );
}
