import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final name = state is HomeLoaded ? state.driverName : 'Driver';
        final subtitle = state is HomeLoaded
            ? (!state.isOnline || state.isFromCache
                  ? 'Showing latest synced data'
                  : 'Stay safe on the road')
            : 'Stay safe on the road';

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryColor, width: 0.5),
                ),
                child: ClipOval(
                  child: Icon(
                    Icons.person,
                    size: 32.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $name',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.blackColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w300,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
