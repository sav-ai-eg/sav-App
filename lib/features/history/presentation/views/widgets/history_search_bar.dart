import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/history/presentation/cubit/history_cubit.dart';

class HistorySearchBar extends StatelessWidget {
  const HistorySearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.lightGrayColor,
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: (value) {
          context.read<HistoryCubit>().searchByDate(value);
        },
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.blackColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search date, route, or status',
          hintStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.hintColor,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.search_rounded,
            size: 22.sp,
            color: AppColors.grayColor,
          ),
        ),
      ),
    );
  }
}
