import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        // Default values for loading / initial / error
        double awakePercent = 0;
        double distractedPercent = 0;
        String duration = '0 min';
        int totalAlerts = 0;

        if (state is HomeLoaded) {
          awakePercent = state.awakePercentage;
          distractedPercent = state.distractedPercentage;
          duration = state.formattedDuration;
          totalAlerts = state.totalAlerts;
        }

        final isLoading = state is HomeLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Today Statistics',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.blackColor,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: _AwakeBigCard(
                    awakePercent: awakePercent,
                    duration: duration,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    children: [
                      _DistractedCard(
                          distractedPercent: distractedPercent),
                      SizedBox(height: 8.h),
                      _AlertsCard(totalAlerts: totalAlerts),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AwakeBigCard extends StatelessWidget {
  final double awakePercent;
  final String duration;

  const _AwakeBigCard({
    required this.awakePercent,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174.h,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16.w,
            top: 16.h,
            child: SvgPicture.asset(
              AppAssets.moonStarsIcon,
              width: 50.w,
              height: 50.h,
              colorFilter: const ColorFilter.mode(
                AppColors.tealAlt,
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned(
            right: 12.w,
            bottom: 16.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Awake',
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  '${awakePercent.toStringAsFixed(0)} %',
                  style: GoogleFonts.roboto(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  duration,
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistractedCard extends StatelessWidget {
  final double distractedPercent;

  const _DistractedCard({required this.distractedPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83.h,
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 13.w),
        child: Row(
          children: [
            SvgPicture.asset(
              AppAssets.zonePersonAlertIcon,
              width: 36.w,
              height: 36.h,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distracted',
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${distractedPercent.toStringAsFixed(0)} %',
                  style: GoogleFonts.roboto(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final int totalAlerts;

  const _AlertsCard({required this.totalAlerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83.h,
      decoration: BoxDecoration(
        color: AppColors.salmonLight,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            SvgPicture.asset(
              AppAssets.alertBellIcon,
              width: 36.w,
              height: 36.h,
              colorFilter: const ColorFilter.mode(
                AppColors.textLight,
                BlendMode.srcIn,
              ),
            ),
            const Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Alerts',
                  style: GoogleFonts.roboto(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.navyText,
                  ),
                ),
                Text(
                  '$totalAlerts',
                  style: GoogleFonts.roboto(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                Text(
                  'Today',
                  style: GoogleFonts.roboto(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.navyText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
