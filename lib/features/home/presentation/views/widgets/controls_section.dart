import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';
import 'package:sav/features/home/presentation/views/widgets/duty_calendar_dialog.dart';
import 'package:sav/features/common/chat/presentation/cubit/chat_unread_summary_cubit.dart';

class ControlsSection extends StatelessWidget {
  const ControlsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Controls',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 24.h),
        const _WeekScheduleCard(),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _EmergencyButton()),
            SizedBox(width: 16.w),
            Expanded(child: _InboxButton()),
          ],
        ),
      ],
    );
  }
}

class _WeekScheduleCard extends StatelessWidget {
  const _WeekScheduleCard();

  // Dart weekdays: 1=Mon..7=Sun. We display Sat first.
  static const _dayLabels = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  // Dart weekday values: Sat=6, Sun=7, Mon=1, ..., Fri=5
  static const _weekdayValues = [6, 7, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final weekDuty = state is HomeLoaded
            ? state.weekDuty
            : <int, DutyLevel>{};
        final monthDuty = state is HomeLoaded
            ? state.monthDuty
            : <DateTime, DutyLevel>{};
        final focusedMonth = state is HomeLoaded
            ? state.focusedMonth
            : DateTime.now();
        final isMonthLoading = state is HomeLoaded && state.isMonthLoading;

        return GestureDetector(
          onTap: isMonthLoading
              ? null
              : () async {
                  await showDutyCalendarDialog(
                    context: context,
                    dutyByDate: monthDuty,
                    focusedMonth: focusedMonth,
                    selectedDate: DateTime.now(),
                    onMonthChanged: (month) {
                      context.read<HomeCubit>().loadDutyForMonth(month);
                    },
                  );
                },
          child: Container(
            height: 110.h,
            decoration: BoxDecoration(
              color: AppColors.darkNavy,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_dayLabels.length, (i) {
                  final duty = weekDuty[_weekdayValues[i]] ?? DutyLevel.off;

                  return _DayColumn(name: _dayLabels[i], duty: duty);
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DayColumn extends StatelessWidget {
  final String name;
  final DutyLevel duty;

  const _DayColumn({required this.name, required this.duty});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 19.h),
        Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _dutyColor(duty),
          ),
        ),
      ],
    );
  }

  Color _dutyColor(DutyLevel duty) {
    switch (duty) {
      case DutyLevel.high:
        return AppColors.primaryColor;
      case DutyLevel.low:
        return AppColors.salmonLight;
      case DutyLevel.off:
        return Colors.white;
    }
  }
}

class _EmergencyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushWithNamed(Routes.emergencyView);
      },
      child: Container(
        height: 58.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Emergency',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.176,
              ),
            ),
            SizedBox(width: 16.w),
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.warningTriangle,
                  width: 16.w,
                  height: 16.h,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.pushWithNamed(Routes.chatConversationsView).then((_) {
          if (context.mounted) {
            context.read<ChatUnreadSummaryCubit>().refreshUnreadSummary();
          }
        });
      },
      child: Container(
        height: 58.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.salmonLight,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Inbox',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.darkNavy,
                letterSpacing: -0.176,
              ),
            ),
            SizedBox(width: 12.w),
            BlocBuilder<ChatUnreadSummaryCubit, ChatUnreadSummaryState>(
              builder: (context, state) {
                final unreadCount = state.summary?.totalUnreadMessages ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: Center(
                        child: SvgPicture.asset(
                          AppAssets.inbox,
                          width: 20.w,
                          height: 20.h,
                          colorFilter: const ColorFilter.mode(
                            AppColors.darkNavy,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4.w,
                        top: -4.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadCount',
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
