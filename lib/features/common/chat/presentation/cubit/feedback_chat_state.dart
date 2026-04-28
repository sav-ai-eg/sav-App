import 'package:flutter/foundation.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';

enum FeedbackChatStatus { initial, loading, loaded, sending, error }

@immutable
class FeedbackChatState {
  final List<ChatMessage> messages;
  final FeedbackChatStatus status;
  final String? errorMessage;
  final int? conversationId;

  const FeedbackChatState({
    required this.messages,
    required this.status,
    required this.errorMessage,
    required this.conversationId,
  });

  factory FeedbackChatState.initial({required List<ChatMessage> messages}) {
    return FeedbackChatState(
      messages: List<ChatMessage>.unmodifiable(messages),
      status: FeedbackChatStatus.initial,
      errorMessage: null,
      conversationId: null,
    );
  }

  bool get isLoading => status == FeedbackChatStatus.loading;

  bool get isSending => status == FeedbackChatStatus.sending;

  FeedbackChatState copyWith({
    List<ChatMessage>? messages,
    FeedbackChatStatus? status,
    String? errorMessage,
    int? conversationId,
    bool clearErrorMessage = false,
  }) {
    return FeedbackChatState(
      messages: List<ChatMessage>.unmodifiable(messages ?? this.messages),
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
