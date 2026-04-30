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

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isIncoming
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          if (message.senderName.isNotEmpty)
            _SenderLabel(senderName: message.senderName),
          _BubbleBody(
            text: message.text,
            isIncoming: isIncoming,
            bubbleColor: bubbleColor,
            createdAt: message.createdAt,
          ),
        ],
      ),
    );
  }
}

class _SenderLabel extends StatelessWidget {
  final String senderName;

  const _SenderLabel({required this.senderName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        senderName,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.grayColor,
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  final String text;
  final bool isIncoming;
  final Color bubbleColor;
  final DateTime? createdAt;

  const _BubbleBody({
    required this.text,
    required this.isIncoming,
    required this.bubbleColor,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        minHeight: 44.h,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(isIncoming ? 4.r : 20.r),
          bottomRight: Radius.circular(isIncoming ? 20.r : 4.r),
        ),
        boxShadow: [
          BoxShadow(
            color: bubbleColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.4,
            ),
            softWrap: true,
          ),
          if (createdAt != null) ...[
            SizedBox(height: 5.h),
            Text(
              _formatTime(createdAt!),
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.72),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
