import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/widgets/sav_components.dart';
import 'package:sav/features/auth/presentation/views/widgets/driver_text_field.dart';
import 'package:sav/features/trip/data/models/trip_place_model.dart';

class TripLocationField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool isLoading;
  final bool enabled;
  final TripPlaceModel? selectedPlace;
  final List<TripPlaceModel> suggestions;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<TripPlaceModel> onSuggestionSelected;
  final VoidCallback? onClear;

  const TripLocationField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isLoading,
    required this.enabled,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
    this.validator,
    this.onSubmitted,
    this.selectedPlace,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DriverTextField(
          controller: controller,
          focusNode: focusNode,
          label: label,
          hint: hint,
          icon: icon,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          onFieldSubmitted: onSubmitted,
          textInputAction: TextInputAction.next,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          suffixIcon: isLoading
              ? Padding(
                  padding: EdgeInsets.all(14.w),
                  child: SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryColor,
                    ),
                  ),
                )
              : controller.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.subtitleGray,
                  ),
                ),
        ),
        if (selectedPlace != null &&
            selectedPlace!.subtitle.trim().isNotEmpty) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successColor,
                  size: 16,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    selectedPlace!.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          SizedBox(height: 12.h),
          SavCard(
            borderRadius: 16,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 232.h),
              child: ListView.separated(
                itemCount: suggestions.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: AppColors.lightGrayColor,
                ),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return InkWell(
                    onTap: () => onSuggestionSelected(suggestion),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: AppColors.accentColor.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  suggestion.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimaryColor,
                                  ),
                                ),
                                if (suggestion.subtitle.trim().isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  Text(
                                    suggestion.subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondaryColor,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
