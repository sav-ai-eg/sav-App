import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/widgets/sav_components.dart';
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
    final secondaryLabel = model.isNotEmpty ? 'Model:' : 'Company:';
    final secondaryValue = model.isNotEmpty
        ? model
        : (company.isNotEmpty ? company : '—');

    return SavCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Truck icon inside circular background
          Container(
            width: 64.w,
            height: 64.w,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              AppAssets.truckIcon,
              colorFilter: const ColorFilter.mode(
                AppColors.primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          // Vehicle details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VehicleRow(
                  label: 'Plate:',
                  value: plate.isNotEmpty ? plate : '—',
                ),
                SizedBox(height: 6.h),
                _VehicleRow(
                  label: secondaryLabel,
                  value: secondaryValue,
                ),
                if (status.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  _VehicleRow(label: 'Status:', value: status),
                ],
                if (mileage > 0) ...[
                  SizedBox(height: 6.h),
                  _VehicleRow(label: 'Mileage:', value: '$mileage KM'),
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
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryColor,
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
