import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/services/location_service.dart';
import 'package:sav/core/widgets/sav_button.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';

class AssignedTripsView extends StatefulWidget {
  final List<TripEntity> trips;

  const AssignedTripsView({
    super.key,
    required this.trips,
  });

  @override
  State<AssignedTripsView> createState() => _AssignedTripsViewState();
}

class _AssignedTripsViewState extends State<AssignedTripsView> {
  TripEntity? _selectedTrip;
  StreamSubscription<Position>? _positionSubscription;
  bool _showAutoStartPrompt = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  DateTime? _lastCancelledTime;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    // Default select the first trip if available
    if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
    }
    _startSpeedMonitoring();
  }

  @override
  void didUpdateWidget(covariant AssignedTripsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Adjust selected trip if trips list changes
    if (widget.trips.isEmpty) {
      _selectedTrip = null;
    } else if (_selectedTrip == null || !widget.trips.contains(_selectedTrip)) {
      _selectedTrip = widget.trips.first;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startSpeedMonitoring() async {
    final locationService = GetIt.instance<LocationService>();
    final ready = await locationService.isReady();
    if (!ready) {
      final granted = await locationService.requestPermission();
      if (!granted) return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen((position) async {
      if (!mounted) return;

      final speed = position.speed; // in m/s
      final hasTrip = _selectedTrip != null;
      final notStarting = !_isStarting;
      final notPrompting = !_showAutoStartPrompt;

      // Check persistent cooldown
      final prefs = await SharedPreferences.getInstance();
      final cooldownStr = prefs.getString('sav_auto_start_cooldown_until');
      bool notInCooldown = true;
      if (cooldownStr != null) {
        final cooldownUntil = DateTime.tryParse(cooldownStr);
        if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) {
          notInCooldown = false;
        }
      }

      // Memory fallback cooldown if needed
      if (_lastCancelledTime != null &&
          DateTime.now().difference(_lastCancelledTime!) <= const Duration(minutes: 5)) {
        notInCooldown = false;
      }

      if (speed > 1.5 && hasTrip && notStarting && notPrompting && notInCooldown) {
        _triggerAutoStartCountdown();
      }
    }, onError: (err) {
      debugPrint('AssignedTripsView speed monitoring error: $err');
    });
  }

  void _triggerAutoStartCountdown() {
    setState(() {
      _showAutoStartPrompt = true;
      _countdownSeconds = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdownSeconds > 1) {
          _countdownSeconds--;
        } else {
          _countdownTimer?.cancel();
          _showAutoStartPrompt = false;
          _startTripDirectly();
        }
      });
    });
  }

  void _cancelAutoStart() async {
    _countdownTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final cooldownUntil = DateTime.now().add(const Duration(minutes: 5));
    await prefs.setString('sav_auto_start_cooldown_until', cooldownUntil.toIso8601String());
    setState(() {
      _showAutoStartPrompt = false;
      _lastCancelledTime = DateTime.now();
    });
  }

  void _startTripDirectly() async {
    if (_selectedTrip == null || _isStarting) return;
    setState(() {
      _isStarting = true;
    });

    final cubit = context.read<TripCubit>();
    await cubit.startExistingTrip(
      tripId: _selectedTrip!.tripIdOrZero,
    );

    if (mounted) {
      setState(() {
        _isStarting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTrips = widget.trips.isNotEmpty;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primaryColor,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await context.read<TripCubit>().loadAssignedTrips();
          },
          child: hasTrips ? _buildTripsList() : _buildEmptyState(),
        ),
        if (_showAutoStartPrompt)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 56.w,
                              height: 56.w,
                              child: CircularProgressIndicator(
                                value: _countdownSeconds / 5,
                                strokeWidth: 4.w,
                                color: AppColors.primaryColor,
                                backgroundColor: AppColors.lightGrayColor,
                              ),
                            ),
                            Text(
                              '$_countdownSeconds',
                              style: GoogleFonts.inter(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        'Motion Detected!',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'It looks like you started driving. Auto-starting Route #${_selectedTrip?.id} in $_countdownSeconds seconds...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppColors.textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelAutoStart,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.darkGrayColor,
                                side: const BorderSide(color: AppColors.lightGrayColor),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _countdownTimer?.cancel();
                                setState(() {
                                  _showAutoStartPrompt = false;
                                });
                                _startTripDirectly();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Start Now',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildTripsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: widget.trips.length,
      itemBuilder: (context, index) {
        final trip = widget.trips[index];
        final isSelected = _selectedTrip?.id == trip.id;

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: SavCard(
            onTap: () {
              setState(() {
                _selectedTrip = trip;
              });
            },
            color: Colors.white,
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Route #${trip.id}',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Planned',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.radio_button_checked_rounded,
                          color: AppColors.secondaryColor,
                          size: 16.sp,
                        ),
                        Container(
                          width: 1.5,
                          height: 24.h,
                          color: AppColors.lightGrayColor,
                        ),
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primaryColor,
                          size: 16.sp,
                        ),
                      ],
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.from.isNotEmpty ? trip.from : 'Unknown Origin',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            trip.to.isNotEmpty ? trip.to : 'Unknown Destination',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  SizedBox(height: 16.h),
                  SavButton(
                    text: 'Start Trip',
                    icon: Icons.play_arrow_rounded,
                    isLoading: _isStarting,
                    onPressed: () => _startTripDirectly(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SeenEmptyState(
      icon: Icons.route_outlined,
      title: 'No Trips Assigned',
      subtitle: 'Ask your administrator to create and assign a trip to you from the admin panel.',
      action: SavButton(
        text: 'Check for Trips',
        icon: Icons.refresh_rounded,
        onPressed: () {
          context.read<TripCubit>().loadAssignedTrips();
        },
      ),
    );
  }
}
