import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/util/routing/routes.dart';
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
    final adminNames = _extractAdminNames(messages);
    final size = MediaQuery.sizeOf(context);
    final availableHeight =
        size.height - MediaQuery.paddingOf(context).top - 12.h;
    final maxSheetHeight = availableHeight > 0 ? availableHeight : size.height;
    final minSheetHeight = maxSheetHeight < 420.0 ? maxSheetHeight : 420.0;
    final cappedMaxHeight = maxSheetHeight < 720.0 ? maxSheetHeight : 720.0;
    final sheetHeight = (size.height * 0.75)
        .clamp(minSheetHeight, cappedMaxHeight)
        .toDouble();

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Column(
            children: [
              _ChatHeader(
                onClose: onClose,
                onOpenConversations: () {
                  Navigator.of(context).pushNamed(Routes.chatConversationsView);
                },
                adminNames: adminNames,
              ),
              Expanded(
                child: _MessagesArea(messages: messages, isLoading: isLoading),
              ),
              ChatInputBar(
                controller: controller,
                onSend: onSend,
                enabled: !isSending && !isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _extractAdminNames(List<ChatMessage> messages) {
    final seen = <String>{};
    final names = <String>[];

    for (final message in messages) {
      if (!message.isIncoming) {
        continue;
      }

      final normalized = message.senderName.trim();
      if (normalized.isEmpty) {
        continue;
      }

      if (seen.add(normalized)) {
        names.add(normalized);
      }
    }

    return names;
  }
}

class _ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onOpenConversations;
  final List<String> adminNames;

  const _ChatHeader({
    required this.onClose,
    required this.onOpenConversations,
    required this.adminNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.lightGrayColor,
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                const Expanded(child: _ChatHeaderTitle()),
                _HeaderActionButton(
                  icon: Icons.forum_rounded,
                  tooltip: 'Previous chats',
                  onTap: onOpenConversations,
                ),
                SizedBox(width: 8.w),
                _HeaderActionButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close chat',
                  onTap: onClose,
                  filled: true,
                ),
              ],
            ),
            if (adminNames.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: adminNames
                        .map(
                          (name) => Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: _AdminChip(name: name),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  final String name;

  const _AdminChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 180.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.whiteColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeaderTitle extends StatelessWidget {
  const _ChatHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat with Admin',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          'Get help and support',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grayColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MessagesArea extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;

  const _MessagesArea({required this.messages, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const _LoadingMessagesState();
    }

    if (messages.isEmpty) {
      return const _EmptyMessagesState();
    }

    return ColoredBox(
      color: AppColors.scaffoldColor,
      child: _MessageList(messages: messages),
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;

  const _MessageList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      cacheExtent: 900,
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];

        return Padding(
          key: ValueKey<String>(message.stableKey),
          padding: EdgeInsets.only(bottom: 12.h),
          child: ChatBubble(message: message),
        );
      },
    );
  }
}

class _LoadingMessagesState extends StatelessWidget {
  const _LoadingMessagesState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.scaffoldColor,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scaffoldColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _EmptyMessagesIcon(),
            SizedBox(height: 16.h),
            Text(
              'No messages yet',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Start a conversation with admin',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grayColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessagesIcon extends StatelessWidget {
  const _EmptyMessagesIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.w,
      height: 64.w,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mail_outline_rounded,
        color: AppColors.primaryColor,
        size: 32.sp,
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String tooltip;
  final bool filled;

  const _HeaderActionButton({
    required this.onTap,
    required this.icon,
    required this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: filled ? AppColors.scaffoldColor : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.lightGrayColor, width: 1),
            ),
            child: Icon(icon, color: AppColors.darkNavy, size: 20.sp),
          ),
        ),
      ),
    );
  }
}
