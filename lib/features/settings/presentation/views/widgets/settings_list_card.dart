import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class SettingsListCard extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsListCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
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
        children: List.generate(items.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? 8.h : 0,
            ),
            child: _SettingsListTile(item: items[index]),
          );
        }),
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final VoidCallback? onTap;

  const SettingsItem({
    required this.title,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF050A0C),
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16.sp,
            color: const Color(0xFF050A0C),
          ),
        ],
      ),
    );
  }
}
