part of 'chat_unread_summary_cubit.dart';

class ChatUnreadSummaryState {
  const ChatUnreadSummaryState({
    required this.summary,
    required this.isLoading,
    required this.errorMessage,
  });

  const ChatUnreadSummaryState.initial()
      : summary = null,
        isLoading = false,
        errorMessage = null;

  final ChatUnreadSummaryEntity? summary;
  final bool isLoading;
  final String? errorMessage;

  ChatUnreadSummaryState copyWith({
    ChatUnreadSummaryEntity? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ChatUnreadSummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}