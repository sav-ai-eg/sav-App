import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/widgets/sav_components.dart';

class SettingsListCard extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsListCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SavCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SettingsListTile(item: items[index]),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.dividerColor.withValues(alpha: 0.3),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.title,
    this.icon,
    this.onTap,
  });
}

class _SettingsListTile extends StatelessWidget {
  final SettingsItem item;

  const _SettingsListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 20.sp,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: AppColors.grayColor,
            ),
          ],
        ),
      ),
    );
  }
}
