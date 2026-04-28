import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isIncoming = message.isIncoming;
    final bubbleColor = isIncoming
        ? AppColors.darkNavy
        : AppColors.primaryColor;
    final alignment = isIncoming ? Alignment.centerLeft : Alignment.centerRight;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(isIncoming ? 0 : 20.r),
      topRight: Radius.circular(isIncoming ? 20.r : 0),
      bottomLeft: Radius.circular(20.r),
      bottomRight: Radius.circular(20.r),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isIncoming ? 265.w : 214.w,
          minHeight: 84.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: -0.165,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
