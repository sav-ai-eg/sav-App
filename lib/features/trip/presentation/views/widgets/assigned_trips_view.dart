import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/trip/domain/entities/trip_entity.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/widgets/trip_slide_action.dart';

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

  @override
  void initState() {
    super.initState();
    // Default select the first trip if available
    if (widget.trips.isNotEmpty) {
      _selectedTrip = widget.trips.first;
    }
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
  Widget build(BuildContext context) {
    final hasTrips = widget.trips.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      appBar: AppBar(
        title: Text(
          'Assigned Routes',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
            color: AppColors.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryColor,
          backgroundColor: Colors.white,
          onRefresh: () async {
            await context.read<TripCubit>().loadAssignedTrips();
          },
          child: hasTrips ? _buildTripsList() : _buildEmptyState(),
        ),
      ),
      bottomNavigationBar: _selectedTrip == null
          ? null
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: TripSlideAction(
                label: 'Slide to Start Trip',
                icon: Icons.play_arrow_rounded,
                color: AppColors.primaryColor,
                onSubmit: () async {
                  final cubit = context.read<TripCubit>();
                  await cubit.startExistingTrip(
                    tripId: _selectedTrip!.tripIdOrZero,
                  );
                  return true;
                },
              ),
            ),
    );
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: widget.trips.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Text(
              'Please select one of the planned trips below assigned by your administrator, then slide the action at the bottom to start driving.',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColors.textSecondaryColor,
                height: 1.4,
              ),
            ),
          );
        }

        final trip = widget.trips[index - 1];
        final isSelected = _selectedTrip?.id == trip.id;

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTrip = trip;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.lightGrayColor,
                  width: isSelected ? 2.w : 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primaryColor.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Route #${trip.id}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Planned',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
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
                            size: 18.sp,
                          ),
                          Container(
                            width: 2.w,
                            height: 32.h,
                            color: AppColors.lightGrayColor,
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primaryColor,
                            size: 18.sp,
                          ),
                        ],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'START POINT',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitleGray,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              trip.from.isNotEmpty ? trip.from : 'Unknown Origin',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 20.h),
                            Text(
                              'DESTINATION',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.subtitleGray,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              trip.to.isNotEmpty ? trip.to : 'Unknown Destination',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
      children: [
        Center(
          child: Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.route_outlined,
              color: AppColors.secondaryColor,
              size: 44.sp,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'No Trips Assigned',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Ask your administrator to create and assign a trip to you from the admin panel.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondaryColor,
            height: 1.4,
          ),
        ),
        SizedBox(height: 32.h),
        ElevatedButton(
          onPressed: () {
            context.read<TripCubit>().loadAssignedTrips();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            elevation: 0,
          ),
          child: Text(
            'Check for Trips',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
