import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
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

class _HistoryBody extends StatefulWidget {
  const _HistoryBody();

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<BottomNavCubit>().setHideNavBar(false);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      context.read<BottomNavCubit>().setHideNavBar(false);
    }
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleScroll(UserScrollNotification notification) {
    if (!mounted || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final navCubit = context.read<BottomNavCubit>();

    switch (notification.direction) {
      case ScrollDirection.reverse:
        navCubit.setHideNavBar(true);
        break;
      case ScrollDirection.forward:
        navCubit.setHideNavBar(false);
        break;
      case ScrollDirection.idle:
        if (notification.metrics.pixels <= 0) {
          navCubit.setHideNavBar(false);
        }
        break;
    }

    return false;
  }

  List<Widget> _buildHeaderSlivers() {
    return <Widget>[
      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      SliverToBoxAdapter(
        child: Center(
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
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: const SliverToBoxAdapter(child: HistorySearchBar()),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        sliver: const SliverToBoxAdapter(child: HistoryFilterRow()),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
    ];
  }

  Widget _buildScrollableHistory({required List<Widget> slivers}) {
    return NotificationListener<UserScrollNotification>(
      onNotification: _handleScroll,
      child: RefreshIndicator(
        color: AppColors.primaryColor,
        onRefresh: () => context.read<HistoryCubit>().loadHistory(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            ...slivers,
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            if (state is HistoryLoading) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const _HistoryLoadingSkeleton(),
              );
            }

            if (state is HistoryError) {
              return _buildScrollableHistory(
                slivers: [
                  ..._buildHeaderSlivers(),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: SeenErrorWidget(
                        message: state.message,
                        onRetry: () =>
                            context.read<HistoryCubit>().loadHistory(),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is HistoryLoaded) {
              return _buildScrollableHistory(
                slivers: [
                  ..._buildHeaderSlivers(),
                  if (state.noticeMessage != null)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverToBoxAdapter(
                        child: _HistoryCacheNotice(
                          message: state.noticeMessage!,
                          cachedAt: state.cachedAt,
                          isFromCache: state.isFromCache,
                        ),
                      ),
                    ),
                  if (state.noticeMessage != null)
                    SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: TripHistoryCard(trip: state.trips[index]),
                        );
                      }, childCount: state.trips.length),
                    ),
                  ),
                ],
              );
            }

            return _buildScrollableHistory(
              slivers: [
                ..._buildHeaderSlivers(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: HistoryEmptyWidget(
                      message: state is HistoryEmpty
                          ? state.message
                          : 'No history found yet.',
                    ),
                  ),
                ),
              ],
            );
          },
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
