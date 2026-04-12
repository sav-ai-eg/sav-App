import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sav/core/constants/app_colors.dart';

/// Custom SVG icon widget for consistent icon rendering across the app.
class SavIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;

  const SavIcon({
    super.key,
    required this.assetPath,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.sp;
    return SvgPicture.asset(
      assetPath,
      width: iconSize,
      height: iconSize,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// A round icon container with configurable background & icon.
class SavRoundIcon extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  const SavRoundIcon({
    super.key,
    this.icon,
    this.svgAsset,
    this.size = 56,
    this.backgroundColor = AppColors.primaryColor,
    this.iconColor = AppColors.whiteColor,
    this.iconSize = 28,
  }) : assert(icon != null || svgAsset != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: svgAsset != null
            ? SvgPicture.asset(
                svgAsset!,
                width: iconSize.sp,
                height: iconSize.sp,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              )
            : Icon(icon, size: iconSize.sp, color: iconColor),
      ),
    );
  }
}

/// Container card used throughout SAV for consistent styling.
class SavCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderRadius;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const SavCard({
    super.key,
    required this.child,
    this.color = AppColors.whiteColor,
    this.borderRadius = 20,
    this.height,
    this.width,
    this.padding,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height?.h,
      width: width?.w ?? double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius.r),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Action button used in the controls section (Emergency, Inbox).
class SavActionButton extends StatelessWidget {
  final String label;
  final Widget trailing;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onTap;

  const SavActionButton({
    super.key,
    required this.label,
    required this.trailing,
    this.backgroundColor = AppColors.primaryColor,
    this.textColor = AppColors.whiteColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: backgroundColor,
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
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.176,
              ),
            ),
            SizedBox(width: 16.w),
            trailing,
          ],
        ),
      ),
    );
  }
}
