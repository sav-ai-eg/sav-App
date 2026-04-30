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
  final Future<void> Function() onSend;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const FeedbackChatSheet({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onClose,
    required this.onRetry,
    required this.isLoading,
    required this.isSending,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final adminNames = _extractAdminNames(messages);
    final hasFatalError = errorMessage != null && messages.isEmpty;

    return Material(
      color: AppColors.whiteColor,
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
            child: _MessagesArea(
              messages: messages,
              isLoading: isLoading,
              errorMessage: errorMessage,
              onRetry: onRetry,
            ),
          ),
          ChatInputBar(
            controller: controller,
            onSend: onSend,
            enabled: !isSending && !isLoading && !hasFatalError,
          ),
        ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 10.h, 16.w, 14.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _HeaderActionButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: onClose,
                ),
                SizedBox(width: 10.w),
                const Expanded(child: _ChatHeaderTitle()),
                SizedBox(width: 10.w),
                _HeaderActionButton(
                  icon: Icons.forum_rounded,
                  tooltip: 'All conversations',
                  onTap: onOpenConversations,
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

class _ChatHeaderTitle extends StatelessWidget {
  const _ChatHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Support',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3.h),
        Text(
          'We will keep this conversation in sync.',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.subtitleGray,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
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

class _MessagesArea extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _MessagesArea({
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && messages.isEmpty) {
      return const _LoadingMessagesState();
    }

    final message = errorMessage;
    if (message != null && messages.isEmpty) {
      return _ChatErrorState(message: message, onRetry: onRetry);
    }

    if (messages.isEmpty) {
      return const _EmptyMessagesState();
    }

    return ColoredBox(
      color: AppColors.whiteColor,
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
      color: AppColors.whiteColor,
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ChatErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.whiteColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68.w,
                height: 68.w,
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.errorColor,
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Chat could not open',
                style: GoogleFonts.inter(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitleGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: AppColors.whiteColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  const _EmptyMessagesState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.whiteColor,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _EmptyMessagesIcon(),
              SizedBox(height: 16.h),
              Text(
                'No messages yet',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkNavy,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Send your first message and the admin team will see it here.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitleGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mark_chat_unread_outlined,
        color: AppColors.primaryColor,
        size: 30.sp,
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
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.primaryColor.withValues(alpha: 0.08)
                  : AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: filled
                    ? AppColors.primaryColor.withValues(alpha: 0.18)
                    : AppColors.lightGrayColor,
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.darkNavy, size: 20.sp),
          ),
        ),
      ),
    );
  }
}
