import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sav/core/constants/app_assets.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/chat/presentation/cubit/chat_conversations_cubit.dart';
import 'package:sav/features/common/chat/presentation/widgets/chat_conversation_item.dart';

class ChatConversationsView extends StatefulWidget {
  const ChatConversationsView({super.key});

  @override
  State<ChatConversationsView> createState() => _ChatConversationsViewState();
}

class _ChatConversationsViewState extends State<ChatConversationsView> {
  final TextEditingController _searchController = TextEditingController();
  late final ChatConversationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ChatConversationsCubit>();
    _cubit.loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldColor,
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
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.darkNavy,
            size: 24.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
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
                fillColor: AppColors.scaffoldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (value) {
                _cubit.refreshConversations(search: value.trim());
              },
            ),
          ),
          // Conversations List
          Expanded(
            child: BlocBuilder<ChatConversationsCubit, ChatConversationsState>(
              builder: (context, state) {
                if (state.conversations.isEmpty && state.isLoading) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                if (state.conversations.isEmpty && !state.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64.sp,
                          color: AppColors.grayColor,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grayColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator.adaptive(
                  onRefresh: () => _cubit.refreshConversations(
                    search: _searchController.text.trim(),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    itemCount: state.conversations.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.conversations.length) {
                        // Load more indicator
                        _cubit.loadMoreConversations(
                          search: _searchController.text.trim(),
                        );
                        return Padding(
                          padding: EdgeInsets.all(16.w),
                          child: const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        );
                      }

                      final conversation = state.conversations[index];
                      final driverName = conversation.driver != null
                          ? '${conversation.driver!.firstName} ${conversation.driver!.lastName}'.trim()
                          : 'Unknown Driver';

                      return ChatConversationItem(
                        id: conversation.id,
                        driverName: driverName,
                        lastMessage: conversation.lastMessage?.text ?? 'No messages yet',
                        lastMessageAt: conversation.lastMessageAt,
                        unreadCount: conversation.unreadCount,
                        onTap: () {
                          // Navigate to chat view with this conversation
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: {'conversationId': conversation.id},
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