import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/home/presentation/cubit/home_cubit.dart';
import 'package:sav/features/home/presentation/views/widgets/header_section.dart';
import 'package:sav/features/home/presentation/views/widgets/statistics_section.dart';
import 'package:sav/features/home/presentation/views/widgets/controls_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadDashboard(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<HomeCubit>().loadDashboard();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                const HeaderSection(),
                SizedBox(height: 24.h),
                const StatisticsSection(),
                SizedBox(height: 24.h),
                const ControlsSection(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}