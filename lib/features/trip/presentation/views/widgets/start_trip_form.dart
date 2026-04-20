import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/constants/app_constants.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/services/connectivity_service.dart';
import 'package:sav/core/services/google_directions_service.dart';
import 'package:sav/core/services/google_places_service.dart';
import 'package:sav/core/services/location_service.dart';
import 'package:sav/core/services/permission_service.dart';
import 'package:sav/core/services/tflite_detection_service.dart';
import 'package:sav/core/widgets/sav_button.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/core/widgets/sav_dialog.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/widgets/trip_location_field.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:uuid/uuid.dart';

class StartTripForm extends StatefulWidget {
  const StartTripForm({super.key});

  @override
  State<StartTripForm> createState() => _StartTripFormState();
}

class _StartTripFormState extends State<StartTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocusNode = FocusNode();
  final _toFocusNode = FocusNode();
  final _placesService = getIt<GooglePlacesService>();
  final _connectivityService = getIt<ConnectivityService>();
  final _locationService = getIt<LocationService>();
  final _directionsService = getIt<GoogleDirectionsService>();
  final _detectionService = getIt<TfliteDetectionService>();

  Timer? _fromDebounce;
  Timer? _toDebounce;
  int _fromRequestId = 0;
  int _toRequestId = 0;
  bool _isSubmitting = false;
  bool _isSearchingFrom = false;
  bool _isSearchingTo = false;
  String? _placesError;
  String _sessionToken = const Uuid().v4();
  List<TripPlaceModel> _fromSuggestions = const [];
  List<TripPlaceModel> _toSuggestions = const [];
  TripPlaceModel? _selectedFrom;
  TripPlaceModel? _selectedTo;

  bool get _hasSuggestions =>
      _fromSuggestions.isNotEmpty || _toSuggestions.isNotEmpty;

  @override
  void dispose() {
    _fromDebounce?.cancel();
    _toDebounce?.cancel();
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final compactMode = keyboardVisible || _hasSuggestions;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: compactMode
                  ? SizedBox(height: 4.h, key: const ValueKey('compact-gap'))
                  : Column(
                      key: const ValueKey('alerts-mode'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TripSectionTitle('Alerts'),
                        SizedBox(height: 12.h),
                        _TripAlertsCard(
                          isOnline: _connectivityService.isOnline,
                          isAiReady: _detectionService.isInitialized,
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
            ),
            const _TripSectionTitle('Route'),
            SizedBox(height: 12.h),
            SavCard(
              borderRadius: 28,
              padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TripLocationField(
                    controller: _fromController,
                    focusNode: _fromFocusNode,
                    label: 'From',
                    hint: 'Starting point',
                    icon: Icons.my_location_rounded,
                    isLoading: _isSearchingFrom,
                    enabled: true,
                    suggestions: _fromSuggestions,
                    selectedPlace: _selectedFrom,
                    validator: _validateFrom,
                    onChanged: (value) =>
                        _handleQueryChanged(value, isFromField: true),
                    onSubmitted: (_) => _toFocusNode.requestFocus(),
                    onSuggestionSelected: (place) =>
                        _selectSuggestion(place, isFromField: true),
                    onClear: () => _clearField(isFromField: true),
                  ),
                  SizedBox(height: 16.h),
                  Container(height: 1, color: AppColors.scaffoldColor),
                  SizedBox(height: 16.h),
                  TripLocationField(
                    controller: _toController,
                    focusNode: _toFocusNode,
                    label: 'To',
                    hint: 'Destination',
                    icon: Icons.location_on_outlined,
                    isLoading: _isSearchingTo,
                    enabled: true,
                    suggestions: _toSuggestions,
                    selectedPlace: _selectedTo,
                    validator: _validateTo,
                    onChanged: (value) =>
                        _handleQueryChanged(value, isFromField: false),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onSuggestionSelected: (place) =>
                        _selectSuggestion(place, isFromField: false),
                    onClear: () => _clearField(isFromField: false),
                  ),
                  if (_placesError != null &&
                      _connectivityService.isOnline) ...[
                    SizedBox(height: 12.h),
                    _InfoBanner(
                      text: 'Search is temporarily unavailable',
                      color: AppColors.warningColor,
                      icon: Icons.wifi_off_rounded,
                    ),
                  ],
                  if (!_connectivityService.isOnline) ...[
                    SizedBox(height: 12.h),
                    const _InfoBanner(
                      text: 'Offline mode',
                      color: AppColors.warningColor,
                      icon: Icons.cloud_off_rounded,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: compactMode
                  ? SizedBox(
                      height: 8.h,
                      key: const ValueKey('controls-hidden'),
                    )
                  : Column(
                      key: const ValueKey('controls-visible'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TripSectionTitle('Your Controls'),
                        SizedBox(height: 12.h),
                        SavButton(
                          text: 'Start Your Trip',
                          icon: Icons.play_arrow_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _onStart,
                          backgroundColor: AppColors.primaryColor,
                          borderRadius: 18,
                          height: 54.h,
                        ),
                        SizedBox(height: 16.h),
                        _TripMapPreviewCard(
                          currentPosition: _locationService.lastPosition,
                          fromPlace: _selectedFrom,
                          toPlace: _selectedTo,
                          isOnline: _connectivityService.isOnline,
                          directionsService: _directionsService,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQueryChanged(String value, {required bool isFromField}) {
    if (isFromField) {
      _selectedFrom = null;
    } else {
      _selectedTo = null;
    }

    final trimmedValue = value.trim();
    final timer = isFromField ? _fromDebounce : _toDebounce;
    timer?.cancel();

    if (!_connectivityService.isOnline ||
        trimmedValue.length < AppConstants.placesQueryMinLength) {
      setState(() {
        if (isFromField) {
          _fromSuggestions = const [];
          _isSearchingFrom = false;
        } else {
          _toSuggestions = const [];
          _isSearchingTo = false;
        }
      });
      return;
    }

    setState(() {
      if (isFromField) {
        _isSearchingFrom = true;
      } else {
        _isSearchingTo = true;
      }
    });

    final requestId = isFromField ? ++_fromRequestId : ++_toRequestId;
    final debounce = Timer(
      const Duration(milliseconds: AppConstants.placesQueryDebounceMs),
      () => _searchPlaces(
        query: trimmedValue,
        isFromField: isFromField,
        requestId: requestId,
      ),
    );

    if (isFromField) {
      _fromDebounce = debounce;
    } else {
      _toDebounce = debounce;
    }
  }

  Future<void> _searchPlaces({
    required String query,
    required bool isFromField,
    required int requestId,
  }) async {
    try {
      final location = _locationService.lastPosition;
      final suggestions = await _placesService.autocomplete(
        query: query,
        sessionToken: _sessionToken,
        latitude: location?.latitude,
        longitude: location?.longitude,
      );

      if (!mounted) {
        return;
      }

      final latestRequestId = isFromField ? _fromRequestId : _toRequestId;
      if (requestId != latestRequestId) {
        return;
      }

      setState(() {
        _placesError = null;
        if (isFromField) {
          _fromSuggestions = suggestions;
          _isSearchingFrom = false;
        } else {
          _toSuggestions = suggestions;
          _isSearchingTo = false;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _placesError = 'Search unavailable';
        if (isFromField) {
          _fromSuggestions = const [];
          _isSearchingFrom = false;
        } else {
          _toSuggestions = const [];
          _isSearchingTo = false;
        }
      });
    }
  }

  Future<void> _selectSuggestion(
    TripPlaceModel place, {
    required bool isFromField,
  }) async {
    setState(() {
      if (isFromField) {
        _isSearchingFrom = true;
      } else {
        _isSearchingTo = true;
      }
    });

    try {
      final detailedPlace = await _placesService.getPlaceDetails(
        place: place,
        sessionToken: _sessionToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _placesError = null;
        if (isFromField) {
          _selectedFrom = detailedPlace;
          _fromController.text = detailedPlace.fullText;
          _fromSuggestions = const [];
          _isSearchingFrom = false;
        } else {
          _selectedTo = detailedPlace;
          _toController.text = detailedPlace.fullText;
          _toSuggestions = const [];
          _isSearchingTo = false;
        }
      });

      if (isFromField) {
        _toFocusNode.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (isFromField) {
          _isSearchingFrom = false;
        } else {
          _isSearchingTo = false;
        }
      });

      SavDialog.showError(context, 'Could not load this location.');
    }
  }

  void _clearField({required bool isFromField}) {
    setState(() {
      if (isFromField) {
        _fromController.clear();
        _selectedFrom = null;
        _fromSuggestions = const [];
        _isSearchingFrom = false;
      } else {
        _toController.clear();
        _selectedTo = null;
        _toSuggestions = const [];
        _isSearchingTo = false;
      }
    });
  }

  String? _validateFrom(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Please enter the start point.';
    }
    if (normalized.toLowerCase() == _toController.text.trim().toLowerCase() &&
        _toController.text.trim().isNotEmpty) {
      return 'Start and destination must be different.';
    }
    return null;
  }

  String? _validateTo(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'Please enter the destination.';
    }
    if (normalized.toLowerCase() == _fromController.text.trim().toLowerCase()) {
      return 'Destination must be different.';
    }
    return null;
  }

  Future<void> _onStart() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final from =
        _selectedFrom ?? TripPlaceModel.manual(_fromController.text.trim());
    final to = _selectedTo ?? TripPlaceModel.manual(_toController.text.trim());

    if (_connectivityService.isOnline &&
        (_selectedFrom == null || _selectedTo == null)) {
      final proceed = await SavDialog.confirm(
        context,
        title: 'Start trip?',
        message: 'Some locations are typed manually. Continue?',
        confirmText: 'Continue',
        icon: Icons.route_rounded,
        confirmColor: AppColors.primaryColor,
      );

      if (!proceed) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = true);

    final permissions = await PermissionService.requestAll(context);
    if (!mounted) {
      return;
    }

    if (!permissions.camera || !permissions.location) {
      setState(() => _isSubmitting = false);
      SavDialog.showError(context, 'Camera and location are required.');
      return;
    }

    await context.read<TripCubit>().startTrip(from: from, to: to);

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    _sessionToken = const Uuid().v4();
  }
}

class _TripSectionTitle extends StatelessWidget {
  final String text;

  const _TripSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryColor,
      ),
    );
  }
}

class _TripAlertsCard extends StatelessWidget {
  final bool isOnline;
  final bool isAiReady;

  const _TripAlertsCard({required this.isOnline, required this.isAiReady});

  @override
  Widget build(BuildContext context) {
    return SavCard(
      borderRadius: 24,
      padding: EdgeInsets.all(18.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'No alerts yet',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _StatusChip(
                  label: isOnline ? 'Online' : 'Offline',
                  icon: isOnline
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: isOnline
                      ? AppColors.successColor
                      : AppColors.warningColor,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatusChip(
                  label: isAiReady ? 'AI Ready' : 'AI Standby',
                  icon: Icons.psychology_rounded,
                  color: isAiReady
                      ? AppColors.successColor
                      : AppColors.secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _InfoBanner({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripMapPreviewCard extends StatefulWidget {
  const _TripMapPreviewCard({
    required this.currentPosition,
    required this.fromPlace,
    required this.toPlace,
    required this.isOnline,
    required this.directionsService,
  });

  final Position? currentPosition;
  final TripPlaceModel? fromPlace;
  final TripPlaceModel? toPlace;
  final bool isOnline;
  final GoogleDirectionsService directionsService;

  @override
  State<_TripMapPreviewCard> createState() => _TripMapPreviewCardState();
}

class _TripMapPreviewCardState extends State<_TripMapPreviewCard> {
  GoogleRouteData? _routeData;
  bool _isRouteLoading = false;
  bool _routeFailed = false;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadRoute(forceLoading: true);
  }

  @override
  void didUpdateWidget(covariant _TripMapPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasChanged =
        oldWidget.fromPlace?.latitude != widget.fromPlace?.latitude ||
        oldWidget.fromPlace?.longitude != widget.fromPlace?.longitude ||
        oldWidget.toPlace?.latitude != widget.toPlace?.latitude ||
        oldWidget.toPlace?.longitude != widget.toPlace?.longitude ||
        oldWidget.isOnline != widget.isOnline;

    if (hasChanged) {
      _loadRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _resolveCenter();
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('center'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ),
    };

    if (widget.fromPlace?.hasCoordinates ?? false) {
      markers.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(widget.fromPlace!.latitude!, widget.fromPlace!.longitude!),
          infoWindow: InfoWindow(title: widget.fromPlace!.title),
        ),
      );
    }

    if (widget.toPlace?.hasCoordinates ?? false) {
      markers.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(widget.toPlace!.latitude!, widget.toPlace!.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: widget.toPlace!.title),
        ),
      );
    }

    final polylinePoints = _buildPolylinePoints();
    final hasRealRoute = _routeData?.hasPath ?? false;

    final polylines = <Polyline>{};
    if (polylinePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_preview'),
          color: hasRealRoute
              ? AppColors.primaryColor
              : AppColors.secondaryColor.withValues(alpha: 0.9),
          width: hasRealRoute ? 5 : 4,
          points: polylinePoints,
          geodesic: true,
          patterns: hasRealRoute
              ? const <PatternItem>[]
              : <PatternItem>[PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return SavCard(
      borderRadius: 28,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 208.h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28.r),
          child: Stack(
            children: [
              AbsorbPointer(
                child: GoogleMap(
                  key: ValueKey(
                    '${center.latitude}_${center.longitude}_${markers.length}_${polylinePoints.length}',
                  ),
                  initialCameraPosition: CameraPosition(
                    target: center,
                    zoom: 13.2,
                  ),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  markers: markers,
                  polylines: polylines,
                ),
              ),
              if (_isRouteLoading && _routeData == null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Skeletonizer(
                      enabled: true,
                      containersColor: AppColors.lightGrayColor,
                      child: Container(
                        color: AppColors.whiteColor.withValues(alpha: 0.52),
                        padding: EdgeInsets.all(14.w),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Bone(
                            height: 36.h,
                            width: double.infinity,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!hasRealRoute &&
                  !_isRouteLoading &&
                  (widget.fromPlace?.hasCoordinates ?? false) &&
                  (widget.toPlace?.hasCoordinates ?? false))
                Positioned(
                  left: 14.w,
                  top: 14.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _routeFailed
                              ? Icons.warning_amber_rounded
                              : Icons.alt_route_rounded,
                          size: 14.sp,
                          color: AppColors.warningColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _routeFailed ? 'Approx route' : 'Static route',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 14.w,
                right: 14.w,
                bottom: 14.h,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _buildLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LatLng> _buildPolylinePoints() {
    if (_routeData?.hasPath ?? false) {
      return _routeData!.points;
    }

    if ((widget.fromPlace?.hasCoordinates ?? false) &&
        (widget.toPlace?.hasCoordinates ?? false)) {
      return <LatLng>[
        LatLng(widget.fromPlace!.latitude!, widget.fromPlace!.longitude!),
        LatLng(widget.toPlace!.latitude!, widget.toPlace!.longitude!),
      ];
    }

    return const <LatLng>[];
  }

  Future<void> _loadRoute({bool forceLoading = false}) async {
    final from = widget.fromPlace;
    final to = widget.toPlace;

    if (!widget.isOnline ||
        from == null ||
        to == null ||
        !from.hasCoordinates ||
        !to.hasCoordinates) {
      if (!mounted) {
        return;
      }

      setState(() {
        _routeData = null;
        _routeFailed = false;
        _isRouteLoading = false;
      });
      return;
    }

    final requestId = ++_routeRequestId;
    if (mounted) {
      setState(() {
        _routeFailed = false;
        _isRouteLoading = forceLoading || _routeData == null;
      });
    }

    try {
      final routeData = await widget.directionsService.getDrivingRoute(
        originLatitude: from.latitude!,
        originLongitude: from.longitude!,
        destinationLatitude: to.latitude!,
        destinationLongitude: to.longitude!,
      );

      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _routeData = routeData.hasPath ? routeData : null;
        _routeFailed = false;
        _isRouteLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      setState(() {
        _routeData = null;
        _routeFailed = true;
        _isRouteLoading = false;
      });
    }
  }

  LatLng _resolveCenter() {
    if (widget.toPlace?.hasCoordinates ?? false) {
      return LatLng(widget.toPlace!.latitude!, widget.toPlace!.longitude!);
    }
    if (widget.fromPlace?.hasCoordinates ?? false) {
      return LatLng(widget.fromPlace!.latitude!, widget.fromPlace!.longitude!);
    }
    if (widget.currentPosition != null) {
      return LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      );
    }
    return const LatLng(31.0409, 31.3785);
  }

  String _buildLabel() {
    if (_routeData?.hasPath ?? false) {
      final distance = _routeData!.distanceText;
      final duration = _routeData!.durationText;
      if (distance.isNotEmpty && duration.isNotEmpty) {
        return 'Live route: $distance - ETA $duration';
      }
    }

    if (widget.fromPlace != null && widget.toPlace != null) {
      return '${widget.fromPlace!.title} to ${widget.toPlace!.title}';
    }
    if (widget.fromPlace != null) {
      return widget.fromPlace!.title;
    }
    if (widget.toPlace != null) {
      return widget.toPlace!.title;
    }
    return 'Map preview';
  }
}
