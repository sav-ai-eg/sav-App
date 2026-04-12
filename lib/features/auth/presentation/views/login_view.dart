import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/auth/presentation/cubit/login_cubit.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          context.pushAndRemoveUntilWithNamed(Routes.bottomNavView);
        } else if (state is LoginFailure) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 358.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                AppAssets.logo,
                                width: 185.w,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 56.h),
                            _AuthField(
                              label: 'Username',
                              hint: 'Enter your username',
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              autofillHints: const [AutofillHints.username],
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.h),
                            _AuthField(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.visiblePassword,
                              autofillHints: const [AutofillHints.password],
                              obscureText: _obscurePassword,
                              onFieldSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                splashRadius: 18.w,
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20.sp,
                                  color: AppColors.hintColor,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 24.h),
                            BlocBuilder<LoginCubit, LoginState>(
                              builder: (context, state) {
                                final isSubmitting = state is LoginSubmitting;

                                return SizedBox(
                                  width: double.infinity,
                                  height: 48.h,
                                  child: ElevatedButton(
                                    onPressed: isSubmitting ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkNavy,
                                      disabledBackgroundColor:
                                          AppColors.darkNavy.withValues(alpha: 0.7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isSubmitting
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.w,
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Login',
                                            style: GoogleFonts.inter(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<LoginCubit>().login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            onFieldSubmitted: onFieldSubmitted,
            textAlignVertical: TextAlignVertical.center,
            autocorrect: false,
            enableSuggestions: !obscureText,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.blackColor,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w300,
                color: const Color(0xFFBDBAB9),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              prefixIcon: prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: 16.sp,
                      color: AppColors.hintColor,
                    ),
              suffixIcon: suffix,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
