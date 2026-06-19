import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';
import 'package:sav/features/settings/data/models/vehicle_info.dart';

class VehicleInfoCard extends StatelessWidget {
  final DriverModel driver;
  final VehicleInfo? vehicle;

  const VehicleInfoCard({super.key, required this.driver, this.vehicle});

  @override
  Widget build(BuildContext context) {
    final plate = vehicle?.plateNumber ?? driver.vehiclePlate;
    final model = vehicle?.modelName ?? '';
    final status = vehicle?.statusLabel ?? '';
    final mileage = vehicle?.mileageKm ?? 0;
    final company = driver.companyName?.trim() ?? '';
    final secondaryLabel = model.isNotEmpty ? 'Model :' : 'Company :';
    final secondaryValue = model.isNotEmpty
        ? model
        : (company.isNotEmpty ? company : '—');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
      child: Row(
        children: [
          // Truck icon
          SizedBox(
            width: 70.w,
            height: 70.w,
            child: SvgPicture.asset(
              AppAssets.truckIcon,
              width: 70.w,
              height: 70.w,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1F2024),
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 24.w),
          // Vehicle details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VehicleRow(
                  label: 'Plate :',
                  value: plate.isNotEmpty ? plate : '—',
                ),
                SizedBox(height: 8.h),
                _VehicleRow(
                  label: secondaryLabel,
                  value: secondaryValue,
                ),
                if (status.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  _VehicleRow(label: 'Status :', value: status),
                ],
                if (mileage > 0) ...[
                  SizedBox(height: 8.h),
                  _VehicleRow(label: 'Mileage :', value: '$mileage KM'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final String label;
  final String value;

  const _VehicleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2024),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF1F2024),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
