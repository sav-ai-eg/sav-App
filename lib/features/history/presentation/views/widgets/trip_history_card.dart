import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/history/data/models/trip_history_model.dart';

class TripHistoryCard extends StatelessWidget {
  const TripHistoryCard({super.key, required this.trip});

  final TripHistoryModel trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metricWidth = constraints.maxWidth >= 320
              ? (constraints.maxWidth - 12.w) / 2
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TopChip(
                    icon: Icons.calendar_today_rounded,
                    label: trip.date,
                    iconColor: AppColors.primaryColor,
                    backgroundColor: AppColors.primaryColor.withValues(
                      alpha: 0.08,
                    ),
                    textColor: const Color(0xFF050A0C),
                  ),
                  _TopChip(
                    icon: Icons.task_alt_rounded,
                    label: trip.displayStatus,
                    iconColor: const Color(0xFF2DB105),
                    backgroundColor: const Color(
                      0xFF2DB105,
                    ).withValues(alpha: 0.12),
                    textColor: const Color(0xFF0D5B00),
                  ),
                  _AlertsChip(alerts: trip.alerts),
                ],
              ),
              SizedBox(height: 16.h),
              _LocationBlock(
                label: 'From',
                primaryValue: trip.compactFrom,
                secondaryValue: trip.from,
                icon: Icons.trip_origin_rounded,
                iconColor: AppColors.primaryColor,
                iconBackground: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
              SizedBox(height: 12.h),
              _LocationBlock(
                label: 'To',
                primaryValue: trip.compactTo,
                secondaryValue: trip.to,
                icon: Icons.location_on_outlined,
                iconColor: AppColors.darkNavy,
                iconBackground: const Color(0xFF050A0C).withValues(alpha: 0.06),
              ),
              SizedBox(height: 16.h),
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerColor.withValues(alpha: 0.55),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Duration',
                      value: trip.displayDuration,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Distance',
                      value: trip.displayDistance,
                      icon: Icons.route_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.label,
    required this.primaryValue,
    required this.secondaryValue,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final String primaryValue;
  final String secondaryValue;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    final hasSecondaryText =
        secondaryValue.trim().isNotEmpty &&
        primaryValue.trim().toLowerCase() !=
            secondaryValue.trim().toLowerCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, size: 20.sp, color: iconColor),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtitleGray,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                primaryValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF050A0C),
                  height: 1.25,
                ),
              ),
              if (hasSecondaryText) ...[
                SizedBox(height: 4.h),
                Text(
                  secondaryValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtitleGray,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 18.sp, color: AppColors.primaryColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtitleGray,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF050A0C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: iconColor),
          SizedBox(width: 6.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 180.w),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsChip extends StatelessWidget {
  const _AlertsChip({required this.alerts});

  final int alerts;

  @override
  Widget build(BuildContext context) {
    final hasAlerts = alerts > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: hasAlerts
            ? AppColors.primaryColor.withValues(alpha: 0.12)
            : const Color(0xFFEEF6EF),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasAlerts
                ? Icons.notifications_active_outlined
                : Icons.shield_outlined,
            size: 14.sp,
            color: hasAlerts ? AppColors.primaryColor : const Color(0xFF2DB105),
          ),
          SizedBox(width: 6.w),
          Text(
            hasAlerts ? '$alerts alerts' : 'No alerts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: hasAlerts
                  ? AppColors.primaryColor
                  : const Color(0xFF0D5B00),
            ),
          ),
        ],
      ),
    );
  }
}
