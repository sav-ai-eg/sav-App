import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/widgets/sav_button.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/core/widgets/sav_dialog.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/widgets/active_trip_widget.dart';
import 'package:sav/features/trip/presentation/views/widgets/start_trip_form.dart';

class TripView extends StatefulWidget {
  const TripView({super.key});

  @override
  State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<TripCubit>().restoreCurrentTrip();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<TripCubit>();
    if (state == AppLifecycleState.paused) {
      cubit.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      cubit.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripCubit, TripState>(
      listenWhen: (previous, current) =>
          previous.hideBottomNav != current.hideBottomNav ||
          current is TripError,
      listener: (context, state) async {
        context.read<BottomNavCubit>().setHideNavBar(state.hideBottomNav);

        if (state is TripError) {
          SavDialog.showError(context, state.message);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.hideBottomNav,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop || !state.hideBottomNav || state is TripEnding) {
              return;
            }

            final shouldEndTrip = await SavDialog.confirm(
              context,
              title: 'Cancel trip?',
              message:
                  'This will cancel the current trip session and stop tracking.',
              confirmText: 'Cancel Trip',
              icon: Icons.cancel_rounded,
              confirmColor: AppColors.errorColor,
            );

            if (shouldEndTrip && context.mounted) {
              await context.read<TripCubit>().cancelTrip();
            }
          },
          child: Scaffold(
            backgroundColor: state.hideBottomNav
                ? Colors.black
                : AppColors.backgroundColor,
            body: state.hideBottomNav
                ? _buildImmersiveContent(context, state)
                : SafeArea(
                    child: Column(
                      children: [
                        SizedBox(height: 24.h),
                        Center(
                          child: Text(
                            'Trips',
                            style: GoogleFonts.inter(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blackColor.withValues(
                                alpha: 0.8,
                              ),
                              letterSpacing: -0.264,
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: _buildStandardContent(context, state),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildImmersiveContent(BuildContext context, TripState state) {
    if (state is TripDangerAlert) {
      return ActiveTripWidget(state: state.activeState, dangerAlert: state);
    }

    if (state is TripEnding) {
      return ActiveTripWidget(state: state.activeState, isEnding: true);
    }

    final activeState = state is TripActive
        ? state
        : context.read<TripCubit>().activeSnapshot;

    if (activeState != null) {
      return ActiveTripWidget(state: activeState);
    }

    return _buildStandardContent(context, state);
  }

  Widget _buildStandardContent(BuildContext context, TripState state) {
    if (state is TripLoading) {
      return _TripLoadingContent(state: state);
    }

    if (state is TripEnded) {
      return _TripEndedContent(state: state);
    }

    if (state is TripError) {
      final activeState = context.read<TripCubit>().activeSnapshot;
      if (activeState != null) {
        return ActiveTripWidget(state: activeState);
      }
    }

    return const StartTripForm();
  }
}

class _TripLoadingContent extends StatelessWidget {
  final TripLoading state;

  const _TripLoadingContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: SavCard(
          borderRadius: 28,
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryColor),
              SizedBox(height: 18.h),
              Text(
                state.title,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                state.message,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripEndedContent extends StatelessWidget {
  final TripEnded state;

  const _TripEndedContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: const BoxDecoration(
                color: AppColors.accentColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 46.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              state.wasCancelled ? 'Trip cancelled' : 'Trip completed',
              style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              state.wasCancelled
                  ? 'Trip cancellation is saved and visible in history.'
                  : 'Your summary is saved and ready in history.',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondaryColor,
              ),
            ),
            SizedBox(height: 24.h),
            SavCard(
              borderRadius: 24,
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: state.duration ?? '-',
                  ),
                  _divider(),
                  _SummaryRow(
                    icon: Icons.straighten_rounded,
                    label: 'Distance',
                    value: state.distance ?? '-',
                  ),
                  _divider(),
                  _SummaryRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    value: '${state.alertCount}',
                    valueColor: state.alertCount > 0
                        ? AppColors.errorColor
                        : AppColors.successColor,
                  ),
                  _divider(),
                  _SummaryRow(
                    icon: Icons.visibility_rounded,
                    label: 'Awake score',
                    value: '${state.awakePercentage.toStringAsFixed(0)}%',
                    valueColor: state.awakePercentage >= 80
                        ? AppColors.successColor
                        : AppColors.warningColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            SavButton(
              text: 'Start New Trip',
              icon: Icons.refresh_rounded,
              onPressed: () => context.read<TripCubit>().resetTrip(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(vertical: 10.h),
    child: const Divider(height: 1, color: AppColors.lightGrayColor),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.secondaryColor),
        SizedBox(width: 12.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grayColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.blackColor,
          ),
        ),
      ],
    );
  }
}
