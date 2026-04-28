import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/core/widgets/sav_skeleton_loading.dart';
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
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) {
        final prevMessage = previous is HomeLoaded
            ? previous.infoMessage
            : null;
        final currMessage = current is HomeLoaded ? current.infoMessage : null;
        return currMessage != null &&
            currMessage.isNotEmpty &&
            currMessage != prevMessage;
      },
      listener: (context, state) {
        if (!context.mounted) {
          return;
        }

        if (state is! HomeLoaded || state.infoMessage == null) {
          return;
        }

        HapticFeedback.selectionClick();
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(state.infoMessage!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: state.isFromCache
                ? AppColors.warningColor
                : AppColors.infoColor,
          ),
        );
      },
      builder: (context, state) {
        if (state is HomeLoading) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldColor,
            body: const SafeArea(child: SavSkeletonLoading()),
          );
        }

        if (state is HomeError) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldColor,
            body: SafeArea(
              child: SeenErrorWidget(
                message: state.message,
                onRetry: () => context.read<HomeCubit>().loadDashboard(),
              ),
            ),
          );
        }

        if (state is HomeEmpty) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldColor,
            body: SafeArea(
              child: SeenEmptyState(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard is not ready',
                subtitle: state.message,
                action: TextButton(
                  onPressed: () => context.read<HomeCubit>().loadDashboard(),
                  child: const Text('Retry'),
                ),
              ),
            ),
          );
        }

        final isRefreshing = state is HomeLoaded && state.isRefreshing;

        return Scaffold(
          backgroundColor: AppColors.scaffoldColor,
          body: SafeArea(
            child: Column(
              children: [
                if (isRefreshing)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primaryColor,
                    backgroundColor: Colors.transparent,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<HomeCubit>().refreshDashboard(),
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
              ],
            ),
          ),
        );
      },
    );
  }
}
