import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/common/chat/presentation/cubit/chat_conversations_cubit.dart';
import 'package:sav/features/common/chat/presentation/widgets/chat_conversation_item.dart';

class ChatConversationsView extends StatefulWidget {
  const ChatConversationsView({super.key});

  @override
  State<ChatConversationsView> createState() => _ChatConversationsViewState();
}

class _ChatConversationsViewState extends State<ChatConversationsView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatConversationsCubit _cubit;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ChatConversationsCubit>();
    _scrollController.addListener(_handleScroll);
    _cubit.loadConversations();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter > 320) {
      return;
    }

    _cubit.loadMoreConversations(search: _searchController.text.trim());
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _cubit.refreshConversations(search: value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        title: Text(
          'Chat Conversations',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.darkNavy,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkNavy, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.whiteColor,
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16.sp,
                  color: AppColors.grayColor,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.grayColor,
                  size: 20.sp,
                ),
                filled: true,
                fillColor: AppColors.primaryColor.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 1.4,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: _handleSearchChanged,
            ),
          ),
          Expanded(
            child: BlocConsumer<ChatConversationsCubit, ChatConversationsState>(
              listener: (context, state) {
                final errorMessage = state.errorMessage;
                if (errorMessage != null && errorMessage.isNotEmpty) {
                  ScaffoldMessenger.of(context)
                    ..removeCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(errorMessage)));
                }
              },
              builder: (context, state) {
                if (state.conversations.isEmpty && state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (state.conversations.isEmpty &&
                    !state.isLoading &&
                    state.errorMessage != null) {
                  return _ConversationsErrorState(
                    message: state.errorMessage!,
                    onRetry: () => _cubit.refreshConversations(
                      search: _searchController.text.trim(),
                    ),
                  );
                }

                if (state.conversations.isEmpty && !state.isLoading) {
                  return _EmptyConversationsState(
                    onStartChat: () {
                      Navigator.of(context).pushNamed(Routes.feedbackChatView);
                    },
                  );
                }

                return RefreshIndicator.adaptive(
                  onRefresh: () => _cubit.refreshConversations(
                    search: _searchController.text.trim(),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    cacheExtent: 900,
                    addAutomaticKeepAlives: false,
                    itemCount:
                        state.conversations.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.conversations.length) {
                        return Padding(
                          padding: EdgeInsets.all(16.w),
                          child: const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }

                      final conversation = state.conversations[index];
                      final driverName = conversation.driver != null
                          ? '${conversation.driver!.firstName} ${conversation.driver!.lastName}'
                                .trim()
                          : 'Unknown Driver';

                      return ChatConversationItem(
                        key: ValueKey<int>(conversation.id),
                        id: conversation.id,
                        driverName: driverName,
                        lastMessage:
                            conversation.lastMessage?.text ?? 'No messages yet',
                        lastMessageAt: conversation.lastMessageAt,
                        unreadCount: conversation.unreadCount,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            Routes.feedbackChatView,
                            arguments: conversation.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ConversationsErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 58.sp,
              color: AppColors.errorColor,
            ),
            SizedBox(height: 14.h),
            Text(
              'Inbox could not load',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
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
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversationsState extends StatelessWidget {
  final VoidCallback onStartChat;

  const _EmptyConversationsState({required this.onStartChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 34.sp,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No conversations yet',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Start a support chat and it will stay here for later.',
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
              onPressed: onStartChat,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Start chat'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
