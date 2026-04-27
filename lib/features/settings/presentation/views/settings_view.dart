import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/services/auth_session_storage.dart';
import 'package:sav/core/services/permission_service.dart';
import 'package:sav/core/services/firestore_service.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/core/widgets/sav_dialog.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/settings/presentation/cubit/settings_state.dart';
import 'package:sav/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:sav/features/settings/presentation/views/widgets/profile_info_card.dart';
import 'package:sav/features/settings/presentation/views/widgets/settings_list_card.dart';
import 'package:sav/features/settings/presentation/views/widgets/settings_section_header.dart';
import 'package:sav/features/settings/presentation/views/widgets/sign_out_button.dart';
import 'package:sav/features/settings/presentation/views/widgets/vehicle_info_card.dart';
import 'package:url_launcher/url_launcher.dart';
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
        getIt<AuthSessionStorage>(),
      )..loadDriverData(),
      child: const _SettingsBody(),
    );
  }
}

class _SettingsBody extends StatefulWidget {
  const _SettingsBody();

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  static const List<int> _detectionIntervals = <int>[
    500,
    750,
    1000,
    1250,
    1500,
    2000,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _setBottomNavHidden(false);
    });
  }

  @override
  void dispose() {
    _setBottomNavHidden(false);
    super.dispose();
  }

  BottomNavCubit? _tryBottomNavCubit() {
    try {
      return context.read<BottomNavCubit>();
    } catch (_) {
      return null;
    }
  }

  void _setBottomNavHidden(bool hidden) {
    if (!mounted) {
      return;
    }
    _tryBottomNavCubit()?.setHideNavBar(hidden);
  }

  bool _onScroll(UserScrollNotification notification) {
    if (!mounted) {
      return false;
    }

    final navCubit = _tryBottomNavCubit();
    if (navCubit == null) {
      return false;
    }

    if (notification.direction == ScrollDirection.reverse) {
      navCubit.setHideNavBar(true);
    } else if (notification.direction == ScrollDirection.forward) {
      navCubit.setHideNavBar(false);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          bloc: settingsCubit,
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            if (state is SettingsError) {
              return _SettingsErrorState(
                message: state.message,
                onRetry: () => context.read<SettingsCubit>().loadDriverData(),
              );
            }

            if (state is! SettingsLoaded) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => context.read<SettingsCubit>().loadDriverData(),
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildContent(state),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(SettingsLoaded state) {
    final driver = state.driver;
    final normalizedRole = state.role.trim();
    final hasCompany = (driver.companyName ?? '').trim().isNotEmpty;
    final hasEmergency = (driver.emergencyContact ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Center(
          child: Text(
            'Setting & Info',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor.withValues(alpha: 0.85),
              letterSpacing: -0.264,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        _SessionHeaderCard(username: state.username, role: normalizedRole),
        SizedBox(height: 16.h),

        SettingsSectionHeader(
          title: 'Profile info',
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(height: 8.h),
        ProfileInfoCard(driver: driver),
        if (hasCompany || hasEmergency) ...[
          SizedBox(height: 8.h),
          _ExtendedProfileCard(
            companyName: driver.companyName,
            emergencyContact: driver.emergencyContact,
          ),
        ],
        SizedBox(height: 16.h),

        SettingsSectionHeader(
          title: 'Vehicle info',
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        VehicleInfoCard(driver: driver),
        SizedBox(height: 16.h),

        SettingsSectionHeader(
          title: 'Quick preferences',
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.h),
        _PreferencesCard(
          alertSoundEnabled: state.alertSoundEnabled,
          vibrationEnabled: state.vibrationEnabled,
          notificationsEnabled: state.notificationsEnabled,
          detectionIntervalMs: state.detectionIntervalMs,
          onAlertSoundChanged: (value) =>
              context.read<SettingsCubit>().setAlertSoundEnabled(value),
          onVibrationChanged: (value) =>
              context.read<SettingsCubit>().setVibrationEnabled(value),
          onNotificationsChanged: (value) =>
              context.read<SettingsCubit>().setNotificationsEnabled(value),
          onEditInterval: () => _showTripSettingsSheet(state),
        ),
        SizedBox(height: 16.h),

        SettingsSectionHeader(title: 'Settings', fontWeight: FontWeight.w500),
        SizedBox(height: 8.h),
        SettingsListCard(
          items: [
            SettingsItem(
              title: 'Trip Settings',
              onTap: () => _showTripSettingsSheet(state),
            ),
            SettingsItem(
              title: 'App Preferences',
              onTap: () => _showAppPreferencesSheet(),
            ),
            SettingsItem(
              title: state.notificationsEnabled
                  ? 'Notifications (Enabled)'
                  : 'Notifications (Disabled)',
              onTap: () async {
                await context.read<SettingsCubit>().setNotificationsEnabled(
                  !state.notificationsEnabled,
                );
                if (!mounted) {
                  return;
                }
                SavDialog.showSuccess(
                  context,
                  state.notificationsEnabled
                      ? 'Notifications disabled.'
                      : 'Notifications enabled.',
                );
              },
            ),
            SettingsItem(
              title: 'Device & Camera',
              onTap: () => _showDeviceStatusSheet(state),
            ),
            SettingsItem(
              title: 'Permissions',
              onTap: () {
                _requestPermissions();
              },
            ),
            SettingsItem(
              title: 'Support',
              onTap: () => _showSupportSheet(state),
            ),
            SettingsItem(
              title: 'About',
              onTap: () {
                _showAboutDialog();
              },
            ),
          ],
        ),
        SizedBox(height: 24.h),

        Align(
          alignment: Alignment.centerLeft,
          child: state.isSigningOut
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              : SignOutButton(
                  onPressed: () {
                    _showSignOutDialog();
                  },
                ),
        ),
        SizedBox(height: 100.h),
      ],
    );
  }

  Future<void> _showTripSettingsSheet(SettingsLoaded state) async {
    int selectedInterval = state.detectionIntervalMs;
    final settingsCubit = context.read<SettingsCubit>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setInnerState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Detection Interval',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Choose how often SAV analyzes camera frames during driving.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppColors.grayColor,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _detectionIntervals.map((interval) {
                      final isSelected = interval == selectedInterval;
                      return ChoiceChip(
                        label: Text(
                          '$interval ms',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.whiteColor
                                : AppColors.primaryColor,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: 0.08,
                        ),
                        side: BorderSide(
                          color: AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                        onSelected: (selected) {
                          if (!selected) {
                            return;
                          }

                          setInnerState(() {
                            selectedInterval = interval;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    selectedInterval <= 1000
                        ? 'Faster detection, higher battery usage.'
                        : 'Balanced performance and battery usage.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.grayColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await settingsCubit.setDetectionIntervalMs(
                          selectedInterval,
                        );

                        if (!mounted) {
                          return;
                        }

                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        SavDialog.showSuccess(
                          context,
                          'Detection interval updated to $selectedInterval ms.',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAppPreferencesSheet() async {
    final settingsCubit = context.read<SettingsCubit>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          bloc: settingsCubit,
          builder: (context, state) {
            if (state is! SettingsLoaded) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Preferences',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.alertSoundEnabled,
                    title: const Text('Alert Sound'),
                    subtitle: const Text('Play warning sounds for detections'),
                    activeThumbColor: AppColors.primaryColor,
                    activeTrackColor: AppColors.primaryColor.withValues(
                      alpha: 0.4,
                    ),
                    onChanged: (value) =>
                        settingsCubit.setAlertSoundEnabled(value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.vibrationEnabled,
                    title: const Text('Vibration'),
                    subtitle: const Text('Vibrate while showing warnings'),
                    activeThumbColor: AppColors.primaryColor,
                    activeTrackColor: AppColors.primaryColor.withValues(
                      alpha: 0.4,
                    ),
                    onChanged: (value) =>
                        settingsCubit.setVibrationEnabled(value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: state.notificationsEnabled,
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive app and trip notifications'),
                    activeThumbColor: AppColors.primaryColor,
                    activeTrackColor: AppColors.primaryColor.withValues(
                      alpha: 0.4,
                    ),
                    onChanged: (value) =>
                        settingsCubit.setNotificationsEnabled(value),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeviceStatusSheet(SettingsLoaded state) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device & Camera Status',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14.h),
              _StatusRow(
                title: 'Session',
                granted: state.hasValidSession,
                grantedLabel: 'Active',
                deniedLabel: 'Expired',
              ),
              SizedBox(height: 8.h),
              _StatusRow(
                title: 'Camera Permission',
                granted: state.cameraPermissionGranted,
                grantedLabel: 'Granted',
                deniedLabel: 'Missing',
              ),
              SizedBox(height: 8.h),
              _StatusRow(
                title: 'Location Permission',
                granted: state.locationPermissionGranted,
                grantedLabel: 'Granted',
                deniedLabel: 'Missing',
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await context
                            .read<SettingsCubit>()
                            .refreshPermissionStatus();
                        if (!mounted) {
                          return;
                        }
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                      child: const Text('Refresh'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.whiteColor,
                      ),
                      onPressed: () async {
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        await _requestPermissions();
                      },
                      child: const Text('Request'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestPermissions() async {
    final result = await PermissionService.requestAll(context);
    if (!mounted) {
      return;
    }

    await context.read<SettingsCubit>().refreshPermissionStatus();

    if (!mounted) {
      return;
    }

    if (result.camera && result.location) {
      SavDialog.showSuccess(context, 'All required permissions are granted.');
    } else {
      SavDialog.showError(
        context,
        'Camera and location permissions are required for safe trip tracking.',
      );
    }
  }

  Future<void> _showSupportSheet(SettingsLoaded state) async {
    final emergencyContact = state.driver.emergencyContact?.trim() ?? '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support & Emergency',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              _SupportActionTile(
                title: 'Call Ambulance (${AppConstants.emergencyAmbulance})',
                icon: Icons.local_hospital_rounded,
                onTap: () => _launchPhone(AppConstants.emergencyAmbulance),
              ),
              _SupportActionTile(
                title: 'Call Police (${AppConstants.emergencyPolice})',
                icon: Icons.local_police_rounded,
                onTap: () => _launchPhone(AppConstants.emergencyPolice),
              ),
              _SupportActionTile(
                title: 'Call Fire (${AppConstants.emergencyFire})',
                icon: Icons.local_fire_department_rounded,
                onTap: () => _launchPhone(AppConstants.emergencyFire),
              ),
              if (emergencyContact.isNotEmpty)
                _SupportActionTile(
                  title: 'Call Emergency Contact ($emergencyContact)',
                  icon: Icons.contact_phone_rounded,
                  onTap: () => _launchPhone(emergencyContact),
                ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchPhone(String number) async {
    final sanitized = number.trim();
    if (sanitized.isEmpty) {
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);

    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        SavDialog.showError(context, 'Unable to open phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        SavDialog.showError(context, 'Unable to open phone dialer.');
      }
    }
  }

  Future<void> _showAboutDialog() {
    return SavDialog.info(
      context,
      title: 'About ${AppConstants.appName}',
      message:
          '${AppConstants.appName} helps drivers detect drowsiness, monitor active trips, and share safer live status with fleet operations.\n\nAPI: ${AppConstants.apiBaseUrl}',
      icon: Icons.info_outline_rounded,
    );
  }

  Future<void> _showSignOutDialog() async {
    final shouldLogout = await SavDialog.confirm(
      context,
      title: 'Sign Out',
      message:
          'Are you sure you want to sign out? All local data will be cleared.',
      confirmText: 'Sign Out',
      icon: Icons.logout_rounded,
      confirmColor: AppColors.errorColor,
    );

    if (!shouldLogout || !mounted) {
      return;
    }

    final failureMessage = await context.read<SettingsCubit>().signOut();

    if (!mounted) {
      return;
    }

    if (failureMessage != null && failureMessage.trim().isNotEmpty) {
      SavDialog.showError(context, failureMessage);
      return;
    }

    context.pushAndRemoveUntilWithNamed(Routes.loginView);
  }
}

class _SettingsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SettingsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36.sp,
              color: AppColors.errorColor,
            ),
            SizedBox(height: 10.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.grayColor,
              ),
            ),
            SizedBox(height: 14.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHeaderCard extends StatelessWidget {
  final String username;
  final String role;

  const _SessionHeaderCard({required this.username, required this.role});

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = username.trim();
    final normalizedRole = role.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  normalizedUsername.isEmpty
                      ? 'Driver Account'
                      : normalizedUsername,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  normalizedRole.isEmpty ? 'Driver' : normalizedRole,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.grayColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtendedProfileCard extends StatelessWidget {
  final String? companyName;
  final String? emergencyContact;

  const _ExtendedProfileCard({
    required this.companyName,
    required this.emergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    final company = companyName?.trim() ?? '';
    final emergency = emergencyContact?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (company.isNotEmpty)
            _CompactInfoRow(label: 'Company', value: company),
          if (company.isNotEmpty && emergency.isNotEmpty) SizedBox(height: 8.h),
          if (emergency.isNotEmpty)
            _CompactInfoRow(label: 'Emergency Contact', value: emergency),
        ],
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompactInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.grayColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.blackColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final bool alertSoundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final int detectionIntervalMs;
  final ValueChanged<bool> onAlertSoundChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onEditInterval;

  const _PreferencesCard({
    required this.alertSoundEnabled,
    required this.vibrationEnabled,
    required this.notificationsEnabled,
    required this.detectionIntervalMs,
    required this.onAlertSoundChanged,
    required this.onVibrationChanged,
    required this.onNotificationsChanged,
    required this.onEditInterval,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: alertSoundEnabled,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(vertical: -2),
            activeThumbColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.4),
            title: Text(
              'Alert Sound',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: onAlertSoundChanged,
          ),
          SwitchListTile.adaptive(
            value: vibrationEnabled,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(vertical: -2),
            activeThumbColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.4),
            title: Text(
              'Vibration',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: onVibrationChanged,
          ),
          SwitchListTile.adaptive(
            value: notificationsEnabled,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(vertical: -2),
            activeThumbColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.4),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            onChanged: onNotificationsChanged,
          ),
          Divider(height: 18.h),
          InkWell(
            onTap: onEditInterval,
            borderRadius: BorderRadius.circular(10.r),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 20.sp,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Detection interval: $detectionIntervalMs ms',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
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
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final bool granted;
  final String grantedLabel;
  final String deniedLabel;

  const _StatusRow({
    required this.title,
    required this.granted,
    required this.grantedLabel,
    required this.deniedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: granted
                ? AppColors.successColor.withValues(alpha: 0.12)
                : AppColors.errorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            granted ? grantedLabel : deniedLabel,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: granted ? AppColors.successColor : AppColors.errorColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SupportActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: AppColors.primaryColor),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: AppColors.grayColor,
            ),
          ],
        ),
      ),
    );
  }
}
