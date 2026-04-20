import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/services/google_directions_service.dart';
import 'package:sav/core/services/trip_navigation_service.dart';
import 'package:sav/core/widgets/sav_dialog.dart';
import 'package:sav/features/trip/domain/entities/trip_event_entity.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/widgets/trip_slide_action.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  bool _isProcessingAction = false;

  final TripNavigationService _navigationService =
      GetIt.instance<TripNavigationService>();

  Timer? _routeDebounce;
  GoogleRouteData? _routeData;
  TripNavigationSnapshot? _navigationSnapshot;
  bool _isRouteLoading = false;
  bool _routeFailed = false;
  int _routeRequestId = 0;

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

    _scheduleRouteRefresh(force: true);
  }

  @override
  void didUpdateWidget(covariant ActiveTripWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final latitude = widget.state.latitude;
    final longitude = widget.state.longitude;
    final destinationChanged =
        oldWidget.state.trip.toLatitude != widget.state.trip.toLatitude ||
        oldWidget.state.trip.toLongitude != widget.state.trip.toLongitude;
    final locationChanged =
        latitude != oldWidget.state.latitude ||
        longitude != oldWidget.state.longitude;

    if (latitude != null &&
        longitude != null &&
        _mapController != null &&
        locationChanged) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(latitude, longitude)),
      );
    }

    if (destinationChanged || locationChanged) {
      _scheduleRouteRefresh(force: destinationChanged);
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
    _routeDebounce?.cancel();
    unawaited(_navigationService.resetSession());
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
            onMapCreated: (controller) {
              _mapController = controller;
              _fitCameraToRoute();
            },
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
                    IconButton(
                      onPressed: widget.isEnding || _isProcessingAction
                          ? null
                          : _showEventsTimeline,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkGrayColor.withValues(
                          alpha: 0.74,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.timeline_rounded, size: 18.sp),
                    ),
                    SizedBox(width: 8.w),
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
                if (_isRouteLoading ||
                    _navigationSnapshot != null ||
                    _routeFailed)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: _NavigationTurnBanner(
                      snapshot: _navigationSnapshot,
                      loading: _isRouteLoading,
                      failed: _routeFailed,
                    ),
                  ),
                if (_isRouteLoading ||
                    (_routeData?.hasPath ?? false) ||
                    _routeFailed)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _RouteInfoChip(
                        loading: _isRouteLoading,
                        failed: _routeFailed,
                        distance:
                            _navigationSnapshot?.remainingDistanceText ??
                            _routeData?.distanceText,
                        eta:
                            _navigationSnapshot?.remainingDurationText ??
                            _routeData?.durationText,
                        isApiKeyMissing:
                            _navigationSnapshot?.isApiKeyMissing ?? false,
                        rerouting: _navigationSnapshot?.didReroute ?? false,
                      ),
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
              if ((_routeData?.hasPath ?? false) && _fitCameraToRoute()) {
                return;
              }

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
            actionBusy: _isProcessingAction || state.isActionInProgress,
            onPauseResume: _handlePauseResume,
            onCancelTrip: _handleCancelTrip,
            onSlideToEnd: () => _confirmEndTrip(context),
            routeDistanceLabel:
                _navigationSnapshot?.remainingDistanceText ??
                _routeData?.distanceText,
            routeEtaLabel:
                _navigationSnapshot?.remainingDurationText ??
                _routeData?.durationText,
            hasLiveRoute: _routeData?.hasPath ?? false,
            routeLoading: _isRouteLoading,
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
    final destination = trip.toLatitude != null && trip.toLongitude != null
        ? LatLng(trip.toLatitude!, trip.toLongitude!)
        : null;

    if ((_routeData?.hasPath ?? false)) {
      return <Polyline>{
        Polyline(
          polylineId: const PolylineId('trip_progress_live_route'),
          color: AppColors.primaryColor,
          width: 6,
          geodesic: true,
          points: _routeData!.points,
        ),
      };
    }

    if (destination == null) {
      return const <Polyline>{};
    }

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('trip_progress_fallback'),
        color: AppColors.secondaryColor.withValues(alpha: 0.95),
        width: 4,
        geodesic: true,
        points: <LatLng>[driverPosition, destination],
        patterns: <PatternItem>[PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  void _scheduleRouteRefresh({bool force = false}) {
    final endpoints = _resolveRouteEndpoints();
    if (endpoints == null) {
      if (!mounted) {
        return;
      }

      unawaited(_navigationService.resetSession());

      setState(() {
        _routeData = null;
        _navigationSnapshot = null;
        _isRouteLoading = false;
        _routeFailed = false;
      });
      return;
    }

    _routeDebounce?.cancel();
    final requestId = ++_routeRequestId;

    if (force) {
      unawaited(
        _refreshRoute(
          endpoints.origin,
          endpoints.destination,
          requestId,
          forceReroute: true,
        ),
      );
      return;
    }

    _routeDebounce = Timer(
      const Duration(milliseconds: 420),
      () => unawaited(
        _refreshRoute(endpoints.origin, endpoints.destination, requestId),
      ),
    );
  }

  Future<void> _refreshRoute(
    LatLng origin,
    LatLng destination,
    int requestId, {
    bool forceReroute = false,
  }) async {
    final hadLiveRoute = _routeData?.hasPath ?? false;

    if (mounted) {
      setState(() {
        _isRouteLoading = forceReroute || _routeData == null;
        _routeFailed = false;
      });
    }

    try {
      final snapshot = await _navigationService.updateNavigation(
        currentPosition: origin,
        destination: destination,
        isOnline: widget.state.isOnline,
        forceReroute: forceReroute,
      );

      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _navigationSnapshot = snapshot;
        _routeData = snapshot.routeData.hasPath ? snapshot.routeData : null;
        _isRouteLoading = false;
        _routeFailed =
            !snapshot.routeData.hasPath &&
            !snapshot.isApiKeyMissing &&
            widget.state.isOnline;
      });

      final shouldRefitCamera =
          !hadLiveRoute || snapshot.didReroute || forceReroute;
      if (shouldRefitCamera) {
        _fitCameraToRoute();
      }
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _isRouteLoading = false;
        _routeFailed = _routeData == null;
      });
    }
  }

  ({LatLng origin, LatLng destination})? _resolveRouteEndpoints() {
    final trip = widget.state.trip;
    final destination = trip.toLatitude != null && trip.toLongitude != null
        ? LatLng(trip.toLatitude!, trip.toLongitude!)
        : null;

    final origin =
        widget.state.latitude != null && widget.state.longitude != null
        ? LatLng(widget.state.latitude!, widget.state.longitude!)
        : (trip.fromLatitude != null && trip.fromLongitude != null
              ? LatLng(trip.fromLatitude!, trip.fromLongitude!)
              : null);

    if (origin == null || destination == null) {
      return null;
    }

    return (origin: origin, destination: destination);
  }

  bool _fitCameraToRoute() {
    final controller = _mapController;
    if (controller == null) {
      return false;
    }

    final route = _routeData;
    if (route == null || !route.hasPath) {
      return false;
    }

    final bounds = route.bounds ?? _latLngBoundsFromPoints(route.points);
    if (bounds == null) {
      return false;
    }

    unawaited(
      controller
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 90))
          .catchError((_) {}),
    );

    return true;
  }

  LatLngBounds? _latLngBoundsFromPoints(List<LatLng> points) {
    if (points.length < 2) {
      return null;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }
      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }
      if (point.longitude < minLng) {
        minLng = point.longitude;
      }
      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    if (minLat == maxLat) {
      minLat -= 0.0005;
      maxLat += 0.0005;
    }

    if (minLng == maxLng) {
      minLng -= 0.0005;
      maxLng += 0.0005;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<bool> _confirmEndTrip(BuildContext context) async {
    if (_isProcessingAction) {
      return false;
    }

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

  Future<void> _handlePauseResume() async {
    if (_isProcessingAction || widget.isEnding) {
      return;
    }

    final isStarted = widget.state.trip.isStarted;
    final confirmed = await SavDialog.confirm(
      context,
      title: isStarted ? 'Pause trip?' : 'Resume trip?',
      message: isStarted
          ? 'Trip tracking will be paused until you resume.'
          : 'Trip tracking will continue from your current location.',
      confirmText: isStarted ? 'Pause' : 'Resume',
      icon: isStarted
          ? Icons.pause_circle_outline_rounded
          : Icons.play_circle_outline_rounded,
      confirmColor: AppColors.primaryColor,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    final cubit = context.read<TripCubit>();
    if (isStarted) {
      await cubit.pauseTrip();
    } else {
      await cubit.resumeTrip();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingAction = false;
    });
  }

  Future<void> _handleCancelTrip() async {
    if (_isProcessingAction || widget.isEnding) {
      return;
    }

    final confirmed = await SavDialog.confirm(
      context,
      title: 'Cancel trip?',
      message: 'This will cancel the current trip and stop all tracking.',
      confirmText: 'Cancel Trip',
      icon: Icons.cancel_rounded,
      confirmColor: AppColors.errorColor,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    await context.read<TripCubit>().cancelTrip();

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessingAction = false;
    });
  }

  Future<void> _showEventsTimeline() async {
    if (_isProcessingAction || widget.isEnding) {
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    try {
      final tripCubit = context.read<TripCubit>();
      final events = await tripCubit.loadActiveTripEvents();
      if (!mounted) {
        return;
      }

      await _presentEventsTimeline(events);
    } catch (error) {
      if (!mounted) {
        return;
      }
      SavDialog.showError(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
        });
      }
    }
  }

  Future<void> _presentEventsTimeline(List<TripEventEntity> events) async {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No timeline events yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrayColor,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Trip Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.lightGrayColor.withValues(alpha: 0.7),
                      height: 1,
                    ),
                    itemBuilder: (_, index) {
                      final event = events[index];
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 4.h,
                        ),
                        leading: Icon(
                          _eventIcon(event.eventType),
                          color: AppColors.primaryColor,
                        ),
                        title: Text(
                          _eventTitle(event.eventType),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                        subtitle: Text(
                          _eventSubtitle(event),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _eventIcon(String eventType) {
    switch (eventType.trim().toLowerCase()) {
      case 'started':
        return Icons.play_circle_outline_rounded;
      case 'stopped':
        return Icons.pause_circle_outline_rounded;
      case 'resumed':
        return Icons.play_arrow_rounded;
      case 'finished':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'location_updated':
        return Icons.my_location_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }

  String _eventTitle(String eventType) {
    final normalized = eventType.trim().toLowerCase();
    switch (normalized) {
      case 'started':
        return 'Trip started';
      case 'stopped':
        return 'Trip paused';
      case 'resumed':
        return 'Trip resumed';
      case 'finished':
        return 'Trip finished';
      case 'cancelled':
        return 'Trip cancelled';
      case 'location_updated':
        return 'Location updated';
      default:
        return normalized.replaceAll('_', ' ');
    }
  }

  String _eventSubtitle(TripEventEntity event) {
    final timestamp = event.createdAt.toLocal();
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    final date =
        '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    final notes = (event.notes ?? '').trim();
    if (notes.isEmpty) {
      return '$date  $hh:$mm';
    }
    return '$date  $hh:$mm  -  $notes';
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
  final bool actionBusy;
  final Future<void> Function() onPauseResume;
  final Future<void> Function() onCancelTrip;
  final Future<bool> Function() onSlideToEnd;
  final String? routeDistanceLabel;
  final String? routeEtaLabel;
  final bool hasLiveRoute;
  final bool routeLoading;

  const _ActiveTripPanel({
    required this.state,
    required this.elapsed,
    required this.isEnding,
    required this.actionBusy,
    required this.onPauseResume,
    required this.onCancelTrip,
    required this.onSlideToEnd,
    required this.routeDistanceLabel,
    required this.routeEtaLabel,
    required this.hasLiveRoute,
    required this.routeLoading,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDistance = (routeDistanceLabel ?? '').trim().isNotEmpty
        ? routeDistanceLabel!
        : state.formattedDistance;

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
                    value: effectiveDistance,
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
              if (routeLoading ||
                  hasLiveRoute ||
                  (routeEtaLabel ?? '').trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: _RouteSummaryStrip(
                    loading: routeLoading,
                    isLiveRoute: hasLiveRoute,
                    etaLabel: routeEtaLabel,
                    distanceLabel: routeDistanceLabel,
                  ),
                ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isEnding || actionBusy ? null : onPauseResume,
                      icon: Icon(
                        state.trip.isStarted
                            ? Icons.pause_circle_outline_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 18.sp,
                      ),
                      label: Text(state.trip.isStarted ? 'Pause' : 'Resume'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isEnding || actionBusy ? null : onCancelTrip,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorColor,
                        side: const BorderSide(color: AppColors.errorColor),
                      ),
                      icon: Icon(Icons.cancel_rounded, size: 18.sp),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TripSlideAction(
                label: 'Slide to end',
                icon: Icons.chevron_right_rounded,
                isLoading: isEnding,
                onSubmit: actionBusy ? () async => false : onSlideToEnd,
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

class _NavigationTurnBanner extends StatelessWidget {
  const _NavigationTurnBanner({
    required this.snapshot,
    required this.loading,
    required this.failed,
  });

  final TripNavigationSnapshot? snapshot;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    if (loading && snapshot == null) {
      return Skeletonizer(
        enabled: true,
        containersColor: AppColors.lightGrayColor,
        child: Bone(
          height: 56.h,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16.r),
        ),
      );
    }

    final currentSnapshot = snapshot;
    if (currentSnapshot == null) {
      if (!failed) {
        return const SizedBox.shrink();
      }

      return _buildHintCard(
        icon: Icons.alt_route_rounded,
        color: AppColors.warningColor,
        title: 'Using approximate route',
        subtitle: 'Live turn-by-turn guidance is temporarily unavailable.',
      );
    }

    if (currentSnapshot.isApiKeyMissing) {
      return _buildHintCard(
        icon: Icons.key_off_rounded,
        color: AppColors.warningColor,
        title: 'Maps key is not configured',
        subtitle:
            'Live navigation is disabled for this build. Route fallback is active.',
      );
    }

    if (!currentSnapshot.hasTurnGuidance) {
      if (currentSnapshot.didReroute) {
        return _buildHintCard(
          icon: Icons.alt_route_rounded,
          color: AppColors.primaryColor,
          title: 'Rerouting...',
          subtitle: 'Updating guidance from your current location.',
        );
      }

      return const SizedBox.shrink();
    }

    final distanceHint =
        currentSnapshot.distanceToManeuverMeters <= 40 ||
            currentSnapshot.distanceToManeuverText.isEmpty
        ? 'Now'
        : 'In ${currentSnapshot.distanceToManeuverText}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _resolveManeuverIcon(currentSnapshot.currentManeuver),
              size: 19.sp,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distanceHint,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  currentSnapshot.currentInstruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                if (currentSnapshot.nextInstruction.trim().isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    'Then ${currentSnapshot.nextInstruction}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (currentSnapshot.didReroute)
            Padding(
              padding: EdgeInsets.only(left: 8.w, top: 2.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.infoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'Rerouted',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.infoColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _resolveManeuverIcon(String maneuver) {
    final normalized = maneuver.trim().toLowerCase();

    if (normalized.contains('uturn') || normalized.contains('u-turn')) {
      return Icons.u_turn_left_rounded;
    }

    if (normalized.contains('left')) {
      return Icons.turn_left_rounded;
    }

    if (normalized.contains('right')) {
      return Icons.turn_right_rounded;
    }

    if (normalized.contains('merge') ||
        normalized.contains('fork') ||
        normalized.contains('ramp')) {
      return Icons.alt_route_rounded;
    }

    if (normalized.contains('roundabout')) {
      return Icons.sync_alt_rounded;
    }

    return Icons.navigation_rounded;
  }
}

class _RouteInfoChip extends StatelessWidget {
  const _RouteInfoChip({
    required this.loading,
    required this.failed,
    required this.distance,
    required this.eta,
    required this.isApiKeyMissing,
    required this.rerouting,
  });

  final bool loading;
  final bool failed;
  final String? distance;
  final String? eta;
  final bool isApiKeyMissing;
  final bool rerouting;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Skeletonizer(
        enabled: true,
        containersColor: AppColors.lightGrayColor,
        child: Bone(
          height: 30.h,
          width: 190.w,
          borderRadius: BorderRadius.circular(999.r),
        ),
      );
    }

    final hasData =
        (distance ?? '').trim().isNotEmpty && (eta ?? '').trim().isNotEmpty;

    final label = isApiKeyMissing
        ? 'Maps key missing'
        : rerouting
        ? 'Rerouting...'
        : failed
        ? 'Using approximate route'
        : (hasData ? '${distance!} • ETA ${eta!}' : 'Live route ready');

    final color = isApiKeyMissing || failed
        ? AppColors.warningColor
        : AppColors.primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApiKeyMissing || failed
                ? Icons.alt_route_rounded
                : Icons.navigation_rounded,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryStrip extends StatelessWidget {
  const _RouteSummaryStrip({
    required this.loading,
    required this.isLiveRoute,
    required this.etaLabel,
    required this.distanceLabel,
  });

  final bool loading;
  final bool isLiveRoute;
  final String? etaLabel;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    if (loading && !isLiveRoute) {
      return Skeletonizer(
        enabled: true,
        containersColor: AppColors.lightGrayColor,
        child: Bone(
          height: 36.h,
          width: double.infinity,
          borderRadius: BorderRadius.circular(12.r),
        ),
      );
    }

    final hasLabels =
        (etaLabel ?? '').trim().isNotEmpty ||
        (distanceLabel ?? '').trim().isNotEmpty;

    if (!hasLabels && !isLiveRoute) {
      return const SizedBox.shrink();
    }

    final label = isLiveRoute ? 'Live route' : 'Approximate route';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.scaffoldColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            isLiveRoute ? Icons.navigation_rounded : Icons.alt_route_rounded,
            size: 16.sp,
            color: isLiveRoute
                ? AppColors.primaryColor
                : AppColors.warningColor,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryColor,
            ),
          ),
          const Spacer(),
          if ((distanceLabel ?? '').trim().isNotEmpty)
            Text(
              distanceLabel!,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
          if ((distanceLabel ?? '').trim().isNotEmpty &&
              (etaLabel ?? '').trim().isNotEmpty)
            Text(
              ' • ',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.grayColor,
              ),
            ),
          if ((etaLabel ?? '').trim().isNotEmpty)
            Text(
              'ETA ${etaLabel!}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryColor,
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
