import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/history/presentation/cubit/history_cubit.dart';
import 'package:sav/features/history/presentation/views/widgets/history_empty_widget.dart';
import 'package:sav/features/history/presentation/views/widgets/history_search_bar.dart';
import 'package:sav/features/history/presentation/views/widgets/history_filter_row.dart';
import 'package:sav/features/history/presentation/views/widgets/trip_history_card.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HistoryCubit>()..loadHistory(),
      child: const _HistoryBody(),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 24.h),

            /// Title
            Center(
              child: Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor.withValues(alpha: 0.8),
                  letterSpacing: -0.264,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            /// Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: BlocBuilder<HistoryCubit, HistoryState>(
                  builder: (context, state) {
                    if (state is HistoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }

                    if (state is HistoryError) {
                      return SeenErrorWidget(
                        message: state.message,
                        onRetry: () => context.read<HistoryCubit>().loadHistory(),
                      );
                    }

                    return Column(
                      children: [
                        /// Search bar
                        const HistorySearchBar(),

                        SizedBox(height: 16.h),

                        /// Filters
                        const HistoryFilterRow(),

                        SizedBox(height: 16.h),

                        /// Trip cards or empty state
                        if (state is HistoryLoaded)
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: state.trips.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 16.h),
                              itemBuilder: (context, index) {
                                return TripHistoryCard(
                                    trip: state.trips[index]);
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: HistoryEmptyWidget(
                              message: state is HistoryEmpty
                                  ? state.message
                                  : 'No history found yet.',
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
