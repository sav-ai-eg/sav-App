import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/history/presentation/cubit/history_cubit.dart';

class HistoryFilterRow extends StatelessWidget {
  const HistoryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final cubit = context.read<HistoryCubit>();
        return Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            /// Add Filter button
            _AddFilterButton(
              onTap: () {
                // TODO: Show filter options bottom sheet
              },
            ),

            /// Filter chips
            _FilterChip(
              label: 'Last Week',
              isActive: cubit.activeFilter == 'Last Week',
              onTap: () => cubit.setFilter('Last Week'),
            ),
          ],
        );
      },
    );
  }
}

class _AddFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2024),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_rounded,
              size: 24.sp,
              color: AppColors.whiteColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'Add Filter',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.whiteColor,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 24.sp,
              color: AppColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryColor : AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.primaryColor, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.whiteColor : AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
