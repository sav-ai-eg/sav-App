import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/auth/presentation/cubit/driver_data_cubit.dart';
import 'package:sav/features/auth/presentation/views/widgets/driver_text_field.dart';

class DriverDataView extends StatelessWidget {
  const DriverDataView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DriverDataCubit>(),
      child: const _DriverDataBody(),
    );
  }
}

class _DriverDataBody extends StatefulWidget {
  const _DriverDataBody();

  @override
  State<_DriverDataBody> createState() => _DriverDataBodyState();
}

class _DriverDataBodyState extends State<_DriverDataBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _companyController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehiclePlateController.dispose();
    _companyController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverDataCubit, DriverDataState>(
      listener: (context, state) {
        if (state is DriverDataSaved) {
          context.pushAndRemoveUntilWithNamed(Routes.bottomNavView);
        } else if (state is DriverDataError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F8),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),

                  // Logo / Icon
                  Center(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.drive_eta_rounded,
                        size: 44.sp,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Title
                  Center(
                    child: Text(
                      'Driver Information',
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Center(
                    child: Text(
                      'Enter your details to get started',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grayColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Name Field
                  DriverTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'e.g. Ahmed Mohamed',
                    icon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Phone Field
                  DriverTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. 01012345678',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // License Number Field
                  DriverTextField(
                    controller: _licenseController,
                    label: 'License Number',
                    hint: 'e.g. 123456789',
                    icon: Icons.badge_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your license number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Vehicle Plate Field
                  DriverTextField(
                    controller: _vehiclePlateController,
                    label: 'Vehicle Plate',
                    hint: 'e.g. ABC 1234',
                    icon: Icons.directions_car_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your vehicle plate';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Company Name (Optional)
                  DriverTextField(
                    controller: _companyController,
                    label: 'Company Name (Optional)',
                    hint: 'e.g. SAV Fleet Co.',
                    icon: Icons.business_outlined,
                  ),
                  SizedBox(height: 16.h),

                  // Emergency Contact (Optional)
                  DriverTextField(
                    controller: _emergencyContactController,
                    label: 'Emergency Contact (Optional)',
                    hint: 'e.g. 01098765432',
                    icon: Icons.emergency_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 32.h),

                  // Submit Button
                  BlocBuilder<DriverDataCubit, DriverDataState>(
                    builder: (context, state) {
                      final isLoading = state is DriverDataLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            disabledBackgroundColor:
                                AppColors.primaryColor.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.w,
                                  child: const CircularProgressIndicator(
                                    color: AppColors.whiteColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.whiteColor,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<DriverDataCubit>().saveDriverData(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            licenseNumber: _licenseController.text.trim(),
            vehiclePlate: _vehiclePlateController.text.trim(),
            companyName: _companyController.text.trim().isNotEmpty
                ? _companyController.text.trim()
                : null,
            emergencyContact:
                _emergencyContactController.text.trim().isNotEmpty
                    ? _emergencyContactController.text.trim()
                    : null,
          );
    }
  }
}
