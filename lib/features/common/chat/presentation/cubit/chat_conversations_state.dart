part of 'chat_conversations_cubit.dart';

class ChatConversationsState {
  const ChatConversationsState({
    required this.conversations,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    required this.errorMessage,
  });

  const ChatConversationsState.initial()
      : conversations = const [],
        isLoading = false,
        hasMore = true,
        currentPage = 0,
        errorMessage = null;

  final List<ChatConversationEntity> conversations;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  ChatConversationsState copyWith({
    List<ChatConversationEntity>? conversations,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) {
    return ChatConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}