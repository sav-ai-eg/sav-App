import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/widgets/sav_dialog.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/widgets/trip_slide_action.dart';

class ActiveTripWidget extends StatefulWidget {
  final TripActive state;
  final TripDangerAlert? dangerAlert;
  final bool isEnding;

  const ActiveTripWidget({
    super.key,
    required this.state,
    this.dangerAlert,
    this.isEnding = false,
  });

  @override
  State<ActiveTripWidget> createState() => _ActiveTripWidgetState();
}

class _ActiveTripWidgetState extends State<ActiveTripWidget>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  GoogleMapController? _mapController;
  late AnimationController _alertAnimController;
  late Animation<double> _alertOpacity;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.state.trip.startTime);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.state.trip.startTime);
        });
      }
    });

    _alertAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _alertOpacity = CurvedAnimation(
      parent: _alertAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant ActiveTripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final latitude = widget.state.latitude;
    final longitude = widget.state.longitude;
    if (latitude != null &&
        longitude != null &&
        _mapController != null &&
        (latitude != oldWidget.state.latitude ||
            longitude != oldWidget.state.longitude)) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    }

    if (widget.dangerAlert != null && oldWidget.dangerAlert == null) {
      _alertAnimController.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _alertAnimController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _mapController?.dispose();
    _alertAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final driverPosition = LatLng(
      state.latitude ?? state.trip.fromLatitude ?? 31.0409,
      state.longitude ?? state.trip.fromLongitude ?? 31.3785,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: driverPosition,
              zoom: 15.2,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildMarkers(driverPosition),
            polylines: _buildPolylines(driverPosition),
            onMapCreated: (controller) => _mapController = controller,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    _TripStatusChip(status: state.detectionStatus),
                    const Spacer(),
                    _DarkGlassChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(_elapsed),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _MiniIndicator(
                        icon: Icons.videocam_rounded,
                        label: 'Cam',
                        active: state.isCameraReady,
                      ),
                      _MiniIndicator(
                        icon: Icons.psychology_rounded,
                        label: 'AI',
                        active: state.isAiReady,
                      ),
                      _MiniIndicator(
                        icon: Icons.wifi_rounded,
                        label: 'Net',
                        active: state.isOnline,
                      ),
                      _MiniIndicator(
                        icon: Icons.gps_fixed_rounded,
                        label: 'GPS',
                        active: state.latitude != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16.w,
          bottom: 330.h,
          child: FloatingActionButton.small(
            heroTag: 'trip_recenter',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: driverPosition, zoom: 16),
                ),
              );
            },
            backgroundColor: AppColors.whiteColor,
            child: Icon(
              Icons.my_location_rounded,
              size: 20.sp,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        Positioned(
          left: 16.w,
          right: 16.w,
          bottom: 18.h,
          child: _ActiveTripPanel(
            state: state,
            elapsed: _elapsed,
            isEnding: widget.isEnding,
            onSlideToEnd: () => _confirmEndTrip(context),
          ),
        ),
        if (widget.dangerAlert != null)
          AnimatedBuilder(
            animation: _alertOpacity,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: AppColors.errorColor.withValues(
                    alpha: 0.34 * _alertOpacity.value,
                  ),
                  child: _alertOpacity.value <= 0.2
                      ? const SizedBox.shrink()
                      : Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 22.w,
                              vertical: 20.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.dangerAlert!.alertType == 'drowsiness'
                                      ? Icons.visibility_off_rounded
                                      : Icons.mood_bad_rounded,
                                  size: 42.sp,
                                  color: AppColors.errorColor,
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  widget.dangerAlert!.alertType == 'drowsiness'
                                      ? 'Drowsiness detected'
                                      : 'Yawning detected',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        if (widget.isEnding)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Ending trip',
                        style: GoogleFonts.inter(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Set<Marker> _buildMarkers(LatLng driverPosition) {
    final trip = widget.state.trip;
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: driverPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };

    if (trip.fromLatitude != null && trip.fromLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(trip.fromLatitude!, trip.fromLongitude!),
          infoWindow: InfoWindow(title: trip.from),
        ),
      );
    }

    if (trip.toLatitude != null && trip.toLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(trip.toLatitude!, trip.toLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: trip.to),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(LatLng driverPosition) {
    final trip = widget.state.trip;
    if (trip.toLatitude == null || trip.toLongitude == null) {
      return const {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('trip_progress'),
        color: AppColors.primaryColor,
        width: 4,
        points: [driverPosition, LatLng(trip.toLatitude!, trip.toLongitude!)],
      ),
    };
  }

  Future<bool> _confirmEndTrip(BuildContext context) async {
    final confirmed = await SavDialog.confirm(
      context,
      title: 'End trip?',
      message: 'Your trip summary will be saved.',
      confirmText: 'End',
      icon: Icons.stop_circle_rounded,
      confirmColor: AppColors.errorColor,
    );

    if (!confirmed || !context.mounted) {
      return false;
    }

    await context.read<TripCubit>().endTrip();
    return true;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _ActiveTripPanel extends StatelessWidget {
  final TripActive state;
  final Duration elapsed;
  final bool isEnding;
  final Future<bool> Function() onSlideToEnd;

  const _ActiveTripPanel({
    required this.state,
    required this.elapsed,
    required this.isEnding,
    required this.onSlideToEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.trip.to,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          state.trip.from,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldColor,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Text(
                            _formatElapsed(elapsed),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const _CameraPreviewCard(),
                ],
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  _MetricTile(
                    icon: Icons.straighten_rounded,
                    label: 'Distance',
                    value: state.formattedDistance,
                    color: AppColors.primaryColor,
                  ),
                  SizedBox(width: 10.w),
                  _MetricTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    value: '${state.alertCount}',
                    color: state.alertCount > 0
                        ? AppColors.errorColor
                        : AppColors.successColor,
                  ),
                  SizedBox(width: 10.w),
                  _MetricTile(
                    icon: Icons.visibility_rounded,
                    label: 'Awake',
                    value: '${state.awakePercentage.toStringAsFixed(0)}%',
                    color: state.awakePercentage >= 80
                        ? AppColors.successColor
                        : state.awakePercentage >= 50
                        ? AppColors.warningColor
                        : AppColors.errorColor,
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              TripSlideAction(
                label: 'Slide to end',
                icon: Icons.chevron_right_rounded,
                isLoading: isEnding,
                onSubmit: onSlideToEnd,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}

class _TripStatusChip extends StatelessWidget {
  final DetectionStatus status;

  const _TripStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label, IconData icon) = switch (status) {
      DetectionStatus.safe => (
        AppColors.successColor,
        'Focused',
        Icons.check_circle_rounded,
      ),
      DetectionStatus.drowsy => (
        AppColors.errorColor,
        'Drowsy',
        Icons.visibility_off_rounded,
      ),
      DetectionStatus.yawning => (
        AppColors.warningColor,
        'Yawning',
        Icons.mood_bad_rounded,
      ),
      DetectionStatus.offline => (
        AppColors.grayColor,
        'Offline',
        Icons.cloud_off_rounded,
      ),
      DetectionStatus.initializing => (
        AppColors.primaryColor,
        'Starting',
        Icons.sync_rounded,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkGlassChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkGlassChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.darkGrayColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _MiniIndicator({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.successColor : AppColors.grayColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.textPrimaryColor : AppColors.grayColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.scaffoldColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20.sp, color: color),
            SizedBox(height: 6.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.grayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewCard extends StatelessWidget {
  const _CameraPreviewCard();

  @override
  Widget build(BuildContext context) {
    final cameraService = context.read<TripCubit>().cameraService;

    return Container(
      width: 96.w,
      height: 118.h,
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: cameraService.isInitialized && cameraService.controller != null
            ? CameraPreview(cameraService.controller!)
            : Center(
                child: Icon(
                  Icons.videocam_off_rounded,
                  size: 24.sp,
                  color: Colors.white60,
                ),
              ),
      ),
    );
  }
}
