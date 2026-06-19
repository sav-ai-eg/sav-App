import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/auth/data/models/driver_model.dart';

class ProfileInfoCard extends StatelessWidget {
  final DriverModel driver;

  const ProfileInfoCard({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return SavCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        children: [
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
                  child: _ProfileImage(avatarUrl: driver.avatarUrl),
                ),
              ),
              SizedBox(width: 14.w),
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name.isNotEmpty ? driver.name : 'Driver',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    _InfoRow(
                      label: 'Phone:',
                      value: driver.phone.isNotEmpty ? driver.phone : '—',
                    ),
                    SizedBox(height: 6.h),
                    _InfoRow(
                      label: 'License:',
                      value: driver.licenseNumber.isNotEmpty
                          ? driver.licenseNumber
                          : '—',
                    ),
                    SizedBox(height: 6.h),
                    _InfoRow(
                      label: 'ID:',
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

class _ProfileImage extends StatelessWidget {
  final String? avatarUrl;

  const _ProfileImage({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final source = _normalizeAvatarUrl(avatarUrl);

    if (source.isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.cover,
      cacheKey: source,
      errorWidget: (_, __, ___) => _fallback(),
      placeholder: (_, __) => _fallback(isLoading: true),
    );
  }

  String _normalizeAvatarUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      return raw;
    }

    if (raw.startsWith('/')) {
      return '${AppConstants.apiBaseUrl}$raw';
    }

    return '${AppConstants.apiBaseUrl}/$raw';
  }

  Widget _fallback({bool isLoading = false}) {
    return Container(
      color: AppColors.scaffoldColor,
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
            )
          : Icon(
              Icons.person,
              size: 40.sp,
              color: AppColors.grayColor,
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
