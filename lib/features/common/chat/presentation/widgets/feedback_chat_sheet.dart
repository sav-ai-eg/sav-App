import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/chat_bubble.dart';
import 'package:sav/features/common/chat/presentation/widgets/chat_input_bar.dart';

class FeedbackChatSheet extends StatelessWidget {
  final List<ChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onClose;
  final bool isLoading;
  final bool isSending;

  const FeedbackChatSheet({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onClose,
    required this.isLoading,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      child: SizedBox(
        height: 538.h,
        width: double.infinity,
        child: Stack(
          children: [
            Container(color: AppColors.scaffoldColor),
            Positioned(
              left: 16.w,
              top: 56.h,
              child: _CloseButton(onTap: onClose),
            ),
            Positioned(
              left: 16.w,
              right: 16.w,
              top: 128.h,
              bottom: 84.h,
              child: isLoading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator.adaptive())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < messages.length; i++) ...[
                            if (i > 0) SizedBox(height: 35.h),
                            ChatBubble(message: messages[i]),
                          ],
                        ],
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ChatInputBar(
                controller: controller,
                onSend: onSend,
                enabled: !isSending,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            AppAssets.close,
            width: 16.w,
            height: 16.h,
            colorFilter: const ColorFilter.mode(
              AppColors.darkGrayColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
