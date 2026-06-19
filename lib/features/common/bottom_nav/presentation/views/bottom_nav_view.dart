import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/common/bottom_nav/presentation/views/widgets/custom_bottom_nav_bar.dart';
import 'package:sav/features/history/presentation/views/history_view.dart';
import 'package:sav/features/home/presentation/views/home_view.dart';
import 'package:sav/features/settings/presentation/views/settings_view.dart';
import 'package:sav/features/trip/presentation/cubit/trip_cubit.dart';
import 'package:sav/features/trip/presentation/views/trip_view.dart';
import 'package:sav/core/services/push_notification_service.dart';

class BottomNavView extends StatefulWidget {
  const BottomNavView({super.key});

  @override
  State<BottomNavView> createState() => _BottomNavViewState();
}

class _BottomNavViewState extends State<BottomNavView> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeView(),
      HistoryView(),
      TripView(),
      SettingsView(),
    ];
    // Initialize push notifications
    getIt<PushNotificationService>().initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripCubit, TripState>(
      listenWhen: (previous, current) => previous is! TripActive && current is TripActive,
      listener: (context, state) {
        context.read<BottomNavCubit>().changeIndex(index: 2);
      },
      child: BlocBuilder<BottomNavCubit, BottomNavState>(
        builder: (context, state) {
          final cubit = context.read<BottomNavCubit>();
        final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
        final shouldHideNav = state.hideNavBar || keyboardVisible;

        return Scaffold(
          backgroundColor: cubit.currentIndex == 2
              ? AppColors.whiteColor
              : AppColors.scaffoldColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: cubit.currentIndex,
                  children: _pages,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    offset: shouldHideNav ? const Offset(0, 1.35) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: shouldHideNav ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: shouldHideNav,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(50.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: CustomBottomNavBar(
                            currentIndex: cubit.currentIndex,
                            bottomNavModels: cubit.bottomNavModels,
                            onItemTap: (index) =>
                                cubit.changeIndex(index: index),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
}
