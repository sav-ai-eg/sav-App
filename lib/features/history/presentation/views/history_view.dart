import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/history/presentation/cubit/history_cubit.dart';
import 'package:sav/features/history/presentation/views/widgets/history_empty_widget.dart';
import 'package:sav/features/history/presentation/views/widgets/history_search_bar.dart';
import 'package:sav/features/history/presentation/views/widgets/history_filter_row.dart';
import 'package:sav/features/history/presentation/views/widgets/trip_history_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
                      return const _HistoryLoadingSkeleton();
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
                            child: RefreshIndicator(
                              color: AppColors.primaryColor,
                              onRefresh: () =>
                                  context.read<HistoryCubit>().loadHistory(),
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: state.trips.length +
                                    (state.noticeMessage == null ? 0 : 1),
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 16.h),
                                itemBuilder: (context, index) {
                                  if (state.noticeMessage != null &&
                                      index == 0) {
                                    return _HistoryCacheNotice(
                                      message: state.noticeMessage!,
                                      cachedAt: state.cachedAt,
                                      isFromCache: state.isFromCache,
                                    );
                                  }

                                  final shift =
                                      state.noticeMessage == null ? 0 : 1;
                                  return TripHistoryCard(
                                    trip: state.trips[index - shift],
                                  );
                                },
                              ),
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

class _HistoryCacheNotice extends StatelessWidget {
  const _HistoryCacheNotice({
    required this.message,
    required this.cachedAt,
    required this.isFromCache,
  });

  final String message;
  final DateTime? cachedAt;
  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    final color = isFromCache ? AppColors.warningColor : AppColors.infoColor;
    final cachedLabel = cachedAt == null
        ? null
        : DateFormat('dd MMM, h:mm a').format(cachedAt!.toLocal());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryColor,
                    height: 1.35,
                  ),
                ),
                if (cachedLabel != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Last sync: $cachedLabel',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingSkeleton extends StatelessWidget {
  const _HistoryLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      containersColor: AppColors.lightGrayColor,
      child: Column(
        children: [
          Bone(
            height: 48.h,
            width: double.infinity,
            borderRadius: BorderRadius.circular(12.r),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Bone(
                height: 40.h,
                width: 120.w,
                borderRadius: BorderRadius.circular(12.r),
              ),
              SizedBox(width: 12.w),
              Bone(
                height: 40.h,
                width: 110.w,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (_, __) => Bone(
                height: 210.h,
                width: double.infinity,
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
