import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

/// Reusable confirmation dialog with SAV design.
class SavDialog {
  SavDialog._();

  /// Show a confirmation dialog and return true if confirmed.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        icon: icon != null
            ? Icon(icon, size: 48.sp, color: confirmColor ?? AppColors.primaryColor)
            : null,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondaryColor,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show a simple info dialog.
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        icon: Icon(icon, size: 48.sp, color: AppColors.primaryColor),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a snackbar message.
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: duration,
      ),
    );
  }

  /// Show an error snackbar.
  static void showError(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.errorColor,
      icon: Icons.error_outline_rounded,
    );
  }

  /// Show a success snackbar.
  static void showSuccess(BuildContext context, String message) {
    showSnackBar(
      context,
      message: message,
      backgroundColor: AppColors.successColor,
      icon: Icons.check_circle_outline_rounded,
    );
  }
}
