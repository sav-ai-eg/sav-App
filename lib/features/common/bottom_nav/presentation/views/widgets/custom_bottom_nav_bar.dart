import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/bottom_nav/data/models/bottom_nav_model.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavModel> bottomNavModels;
  final ValueChanged<int> onItemTap;
  final VoidCallback? onHomeLongPress;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.bottomNavModels,
    required this.onItemTap,
    this.onHomeLongPress,
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
            onLongPress: index == 0 ? onHomeLongPress : null,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final BottomNavModel model;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _NavItem({
    required this.model,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        if (widget.onLongPress != null) {
          _timer = Timer(const Duration(seconds: 5), () {
            widget.onLongPress!();
          });
        }
      },
      onTapUp: (_) {
        _timer?.cancel();
      },
      onTapCancel: () {
        _timer?.cancel();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: SvgPicture.asset(
            widget.model.iconPath,
            key: ValueKey('${widget.model.iconPath}_${widget.isSelected}'),
            width: 24.sp,
            height: 24.sp,
            colorFilter: ColorFilter.mode(
              widget.isSelected ? AppColors.primaryColor : AppColors.grayColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
