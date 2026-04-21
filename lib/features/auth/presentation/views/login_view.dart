import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/util/extensions/navigation.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/core/widgets/sav_button.dart';
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
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  String? _submitErrorMessage;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          TextInput.finishAutofillContext(shouldSave: true);
          if (mounted) {
            setState(() {
              _submitErrorMessage = null;
            });
          }
          context.pushAndRemoveUntilWithNamed(Routes.bottomNavView);
          return;
        }

        if (state is LoginFailure) {
          if (mounted) {
            setState(() {
              _submitErrorMessage = state.message;
            });
          }
        }
      },
      builder: (context, state) {
        final isSubmitting = state is LoginSubmitting;
        final canSubmit =
            _usernameController.text.trim().isNotEmpty &&
                _passwordController.text.trim().isNotEmpty &&
                !isSubmitting;

        return Scaffold(
          backgroundColor: AppColors.scaffoldColor,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactHeight = constraints.maxHeight < 700;
                  final horizontalPadding = constraints.maxWidth >= 720 ? 36.0 : 20.0;
                  final maxContentWidth = constraints.maxWidth >= 1024 ? 460.0 : 420.0;
                  final topPadding = isCompactHeight ? 20.h : 36.h;
                  final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
                  final bottomPadding = (isCompactHeight ? 18.h : 28.h) + keyboardInset;
                  final availableHeight = constraints.maxHeight - topPadding - bottomPadding;
                  final minContentHeight = availableHeight > 0 ? availableHeight : 0.0;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minContentHeight),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Image.asset(
                                      AppAssets.logo,
                                      width: isCompactHeight ? 150.w : 185.w,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(height: isCompactHeight ? 26.h : 40.h),
                                  Text(
                                    'Welcome back',
                                    style: GoogleFonts.inter(
                                      fontSize: isCompactHeight ? 24.sp : 28.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkNavy,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Login with your assigned driver account.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.subtitleGray,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 24.h),
                                  _AuthField(
                                    label: 'Username',
                                    hint: 'Enter your username',
                                    controller: _usernameController,
                                    focusNode: _usernameFocusNode,
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.text,
                                    autofillHints: const [AutofillHints.username],
                                    prefixIcon: Icons.person_outline_rounded,
                                    onChanged: (_) => _onFieldChanged(),
                                    onFieldSubmitted: (_) {
                                      _passwordFocusNode.requestFocus();
                                    },
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
                                    focusNode: _passwordFocusNode,
                                    textInputAction: TextInputAction.done,
                                    keyboardType: TextInputType.visiblePassword,
                                    autofillHints: const [AutofillHints.password],
                                    obscureText: _obscurePassword,
                                    onChanged: (_) => _onFieldChanged(),
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
                                  SizedBox(height: 14.h),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: (_submitErrorMessage == null ||
                                            _submitErrorMessage!.trim().isEmpty)
                                        ? const SizedBox.shrink()
                                        : Container(
                                            key: ValueKey<String>(_submitErrorMessage!),
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 10.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.errorColor.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(14.r),
                                              border: Border.all(
                                                color: AppColors.errorColor.withValues(alpha: 0.25),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 18.sp,
                                                  color: AppColors.errorColor,
                                                ),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: Text(
                                                    _submitErrorMessage!,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.errorColor,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: 18.h),
                                  SavButton(
                                    text: 'Login',
                                    isLoading: isSubmitting,
                                    onPressed: canSubmit ? _submit : null,
                                    backgroundColor: AppColors.darkNavy,
                                    borderRadius: 20,
                                    height: 50,
                                  ),
                                  SizedBox(height: 12.h),
                                ],
                              ),
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
      },
    );
  }

  void _onFieldChanged() {
    if (!mounted) {
      return;
    }

    final hasError = _submitErrorMessage != null;
    if (hasError) {
      setState(() {
        _submitErrorMessage = null;
      });
      return;
    }

    setState(() {});
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_autovalidateMode == AutovalidateMode.disabled) {
        setState(() {
          _autovalidateMode = AutovalidateMode.onUserInteraction;
        });
      }
      return;
    }

    setState(() {
      _submitErrorMessage = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

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
    this.focusNode,
    this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
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
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 9.h),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.none,
          autofillHints: autofillHints,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          textAlignVertical: TextAlignVertical.center,
          autocorrect: false,
          enableSuggestions: !obscureText,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.blackColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFBDBAB9),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: 19.sp,
                    color: AppColors.hintColor,
                  ),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.lightGrayColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: AppColors.lightGrayColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: AppColors.navy,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: AppColors.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: AppColors.errorColor,
                width: 1.2,
              ),
            ),
            errorMaxLines: 2,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
