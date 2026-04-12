import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sav/core/constants/app_colors.dart';

/// Custom skeletonizer-based loading widgets for SAV app.
///
/// Usage:
/// ```dart
/// Skeletonizer(
///   enabled: isLoading,
///   child: YourWidget(),
/// )
/// ```
/// Or use the pre-built skeleton placeholders below.
class SavSkeletonLoading extends StatelessWidget {
  const SavSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      containersColor: AppColors.lightGrayColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            const SavSkeletonHeader(),
            SizedBox(height: 24.h),
            const SavSkeletonStatistics(),
            SizedBox(height: 24.h),
            const SavSkeletonControls(),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder for the home header section.
class SavSkeletonHeader extends StatelessWidget {
  const SavSkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Bone.circle(size: 56.w),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(width: 140.w, fontSize: 12.sp),
              SizedBox(height: 4.h),
              Bone.text(width: 100.w, fontSize: 10.sp),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for the statistics section.
class SavSkeletonStatistics extends StatelessWidget {
  const SavSkeletonStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone.text(width: 180.w, fontSize: 18.sp),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: Bone(
                height: 174.h,
                width: double.infinity,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                children: [
                  Bone(
                    height: 83.h,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  SizedBox(height: 8.h),
                  Bone(
                    height: 83.h,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Skeleton placeholder for the controls section.
class SavSkeletonControls extends StatelessWidget {
  const SavSkeletonControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone.text(width: 130.w, fontSize: 18.sp),
        SizedBox(height: 24.h),
        Bone(
          height: 110.h,
          width: double.infinity,
          borderRadius: BorderRadius.circular(20.r),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Bone(
                height: 56.h,
                width: double.infinity,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Bone(
                height: 56.h,
                width: double.infinity,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Skeleton placeholder for the emergency grid.
class SavSkeletonEmergency extends StatelessWidget {
  const SavSkeletonEmergency({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 48.w) / 2;
    return Skeletonizer(
      enabled: true,
      containersColor: AppColors.lightGrayColor,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            Center(child: Bone.text(width: 130.w, fontSize: 24.sp)),
            SizedBox(height: 32.h),
            Bone.text(width: 200.w, fontSize: 20.sp),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: List.generate(
                4,
                (_) => Bone(
                  height: 174.h,
                  width: cardWidth,
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
