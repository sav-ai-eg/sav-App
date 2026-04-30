import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          border: Border(
            top: BorderSide(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _focusNode,
                  builder: (context, child) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: _focusNode.hasFocus
                            ? AppColors.whiteColor
                            : AppColors.primaryColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 2.h,
                    ),
                    child: _MessageTextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              _SendButton(
                enabled: widget.enabled,
                onTap: () async {
                  await widget.onSend();
                  _focusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  const _MessageTextField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      enabled: enabled,
      maxLines: 4,
      minLines: 1,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryColor,
      ),
      decoration: InputDecoration(
        hintText: enabled ? 'Type message...' : 'Chat is loading...',
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.hintColor,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 10.h),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final Future<void> Function() onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onTap() : null,
        borderRadius: BorderRadius.circular(12.r),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Center(
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ),
      ),
    );
  }
}
