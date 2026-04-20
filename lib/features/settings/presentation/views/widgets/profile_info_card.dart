import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';

class ProfileInfoCard extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback? onEdit;

  const ProfileInfoCard({
    super.key,
    required this.driver,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24.w,
        right: 35.w,
        top: 16.h,
        bottom: 16.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (onEdit != null)
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(999.r),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 22.sp,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              // Avatar with orange border
              Container(
                width: 78.w,
                height: 78.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2.w,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.scaffoldColor,
                    child: Icon(
                      Icons.person,
                      size: 40.sp,
                      color: AppColors.grayColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 13.w),
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name.isNotEmpty ? driver.name : 'Driver',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF050A0C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    _InfoRow(
                      label: 'Phone :',
                      value: driver.phone.isNotEmpty ? driver.phone : '—',
                    ),
                    SizedBox(height: 4.h),
                    _InfoRow(
                      label: 'License :',
                      value: driver.licenseNumber.isNotEmpty
                          ? driver.licenseNumber
                          : '—',
                    ),
                    SizedBox(height: 4.h),
                    _InfoRow(
                      label: 'ID :',
                      value: driver.id.length > 8
                          ? driver.id.substring(0, 8)
                          : driver.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF050A0C),
          ),
        ),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF050A0C),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
