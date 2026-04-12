import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final double fontSize;
  final FontWeight fontWeight;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: fontSize.sp,
          fontWeight: fontWeight,
          color: const Color(0xFF050A0C),
        ),
      ),
    );
  }
}
