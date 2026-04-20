import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/history/presentation/cubit/history_cubit.dart';

class HistoryFilterRow extends StatelessWidget {
  const HistoryFilterRow({super.key});

  static const List<String> _allFilters = <String>[
    'Last Week',
    'Last Month',
    'Finished',
    'Cancelled',
    'With Alerts',
  ];

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
              onTap: () => _showFiltersBottomSheet(context),
            ),

            /// Filter chips
            _FilterChip(
              label: 'Last Week',
              isActive: cubit.activeFilter == 'Last Week',
              onTap: () => cubit.setFilter('Last Week'),
            ),
            _FilterChip(
              label: 'With Alerts',
              isActive: cubit.activeFilter == 'With Alerts',
              onTap: () => cubit.setFilter('With Alerts'),
            ),
            if (cubit.activeFilter != null)
              _FilterChip(
                label: 'Clear',
                isActive: false,
                onTap: () => cubit.setFilter(null),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showFiltersBottomSheet(BuildContext context) async {
    final cubit = context.read<HistoryCubit>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrayColor,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Filter History',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                ..._allFilters.map((filter) {
                  final isSelected = cubit.activeFilter == filter;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.grayColor,
                    ),
                    title: Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    onTap: () {
                      cubit.setFilter(filter);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.errorColor,
                  ),
                  title: Text(
                    'Clear filters',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorColor,
                    ),
                  ),
                  onTap: () {
                    cubit.setFilter(null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
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
