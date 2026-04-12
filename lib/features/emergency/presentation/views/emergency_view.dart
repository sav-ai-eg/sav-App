import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/emergency/presentation/cubit/emergency_cubit.dart';
import 'package:sav/features/emergency/presentation/views/widgets/emergency_type_card.dart';

class EmergencyView extends StatelessWidget {
  const EmergencyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EmergencyCubit>(),
      child: const _EmergencyBody(),
    );
  }
}

class _EmergencyBody extends StatelessWidget {
  const _EmergencyBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmergencyCubit, EmergencyState>(
      listener: (context, state) {
        if (state is EmergencyTriggered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Emergency alert sent successfully!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        } else if (state is EmergencyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send emergency. Please try again.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              SizedBox(height: 24.h),

              /// Title
              Center(
                child: Text(
                  'Emergency',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackColor,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              /// Subtitle
              Text(
                'Choose Emergency Type',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.blackColor,
                ),
              ),

              SizedBox(height: 24.h),

              /// Emergency type cards grid
              BlocBuilder<EmergencyCubit, EmergencyState>(
                builder: (context, state) {
                  final cubit = context.read<EmergencyCubit>();
                  return Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: [
                      EmergencyTypeCard(
                        svgAsset: AppAssets.ambulanceIcon,
                        label: 'Medical Emergency',
                        isSelected:
                            cubit.selectedType == EmergencyType.medical,
                        onTap: () =>
                            cubit.selectType(EmergencyType.medical),
                      ),
                      EmergencyTypeCard(
                        svgAsset: AppAssets.policeIcon,
                        label: 'Police Emergency',
                        isSelected:
                            cubit.selectedType == EmergencyType.police,
                        onTap: () =>
                            cubit.selectType(EmergencyType.police),
                      ),
                      EmergencyTypeCard(
                        svgAsset: AppAssets.fireIcon,
                        label: 'Fire Emergency',
                        isSelected:
                            cubit.selectedType == EmergencyType.fire,
                        onTap: () =>
                            cubit.selectType(EmergencyType.fire),
                      ),
                      EmergencyTypeCard(
                        svgAsset: AppAssets.contactPhone,
                        label: 'Contact\nFleet Manager',
                        isSelected:
                            cubit.selectedType == EmergencyType.fleetManager,
                        onTap: () =>
                            cubit.selectType(EmergencyType.fleetManager),
                      ),
                    ],
                  );
                },
              ),

              const Spacer(),

              /// Send Emergency button
              BlocBuilder<EmergencyCubit, EmergencyState>(
                builder: (context, state) {
                  final cubit = context.read<EmergencyCubit>();
                  final isLoading = state is EmergencyLoading;
                  final hasSelection = cubit.selectedType != null;

                  return SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: (hasSelection && !isLoading)
                          ? () => cubit.triggerEmergency()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        disabledBackgroundColor:
                            AppColors.primaryColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Send Emergency',
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),

              SizedBox(height: 12.h),

              /// Cancel button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cancelButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
