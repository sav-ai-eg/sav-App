import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sav/features/settings/presentation/cubit/settings_state.dart';
import 'package:sav/features/settings/presentation/views/widgets/profile_info_card.dart';
import 'package:sav/features/settings/presentation/views/widgets/settings_list_card.dart';
import 'package:sav/features/settings/presentation/views/widgets/settings_section_header.dart';
import 'package:sav/features/settings/presentation/views/widgets/sign_out_button.dart';
import 'package:sav/features/settings/presentation/views/widgets/vehicle_info_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/features/auth/domain/usecases/logout_use_case.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        getIt<FirestoreService>(),
        getIt<SharedPreferences>(),
        getIt<LogoutUseCase>(),
      )..loadDriverData(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),
              Center(
                child: Text(
                  'Setting & Info',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blackColor.withValues(alpha: 0.8),
                    letterSpacing: -0.264,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: BlocBuilder<SettingsCubit, SettingsState>(
                  builder: (context, state) {
                    if (state is SettingsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    if (state is SettingsError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppColors.grayColor,
                          ),
                        ),
                      );
                    }

                    if (state is SettingsLoaded) {
                      return _buildContent(context, state);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SettingsLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Profile info ──────────────────────
        SettingsSectionHeader(
          title: 'Profile info',
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(height: 8.h),
        ProfileInfoCard(driver: state.driver),
        SizedBox(height: 16.h),

        // ─── Vehicle info ──────────────────────
        SettingsSectionHeader(
          title: 'Vehicle info',
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        VehicleInfoCard(driver: state.driver),
        SizedBox(height: 16.h),

        // ─── Setting ───────────────────────────
        SettingsSectionHeader(
          title: 'Setting',
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        SettingsListCard(
          items: [
            SettingsItem(title: 'Trip Settings', onTap: () {}),
            SettingsItem(title: 'App Preferences', onTap: () {}),
            SettingsItem(title: 'Notifications', onTap: () {}),
            SettingsItem(title: 'Device & Camera', onTap: () {}),
            SettingsItem(title: 'Permissions', onTap: () {}),
            SettingsItem(title: 'Support', onTap: () {}),
            SettingsItem(title: 'About', onTap: () {}),
          ],
        ),
        SizedBox(height: 24.h),

        // ─── Sign Out ──────────────────────────
        SignOutButton(
          onPressed: () => _showSignOutDialog(context),
        ),

        // Extra space for floating bottom nav bar
        SizedBox(height: 100.h),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? All local data will be cleared.',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.grayColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.grayColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<SettingsCubit>().signOut();
              if (context.mounted) {
                context.pushAndRemoveUntilWithNamed(Routes.loginView);
              }
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE70000),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
