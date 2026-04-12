import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/bottom_nav/data/models/bottom_nav_model.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavModel> bottomNavModels;
  final ValueChanged<int> onItemTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.bottomNavModels,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          bottomNavModels.length,
          (index) => _NavItem(
            model: bottomNavModels[index],
            isSelected: currentIndex == index,
            onTap: () => onItemTap(index),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavModel model;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.model,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: SvgPicture.asset(
            model.iconPath,
            key: ValueKey('${model.iconPath}_$isSelected'),
            width: 24.sp,
            height: 24.sp,
            colorFilter: ColorFilter.mode(
              isSelected ? AppColors.primaryColor : AppColors.grayColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
