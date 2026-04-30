import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/usecases/bootstrap_chat_conversation_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/load_chat_conversations_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/load_chat_messages_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/mark_chat_conversation_read_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/send_chat_message_use_case.dart';
import 'package:sav/features/common/chat/presentation/cubit/feedback_chat_state.dart';

class FeedbackChatCubit extends Cubit<FeedbackChatState> {
  FeedbackChatCubit({
    this.initialConversationId,
    BootstrapChatConversationUseCase? bootstrapChatConversationUseCase,
    LoadChatConversationsUseCase? loadChatConversationsUseCase,
    LoadChatMessagesUseCase? loadChatMessagesUseCase,
    SendChatMessageUseCase? sendChatMessageUseCase,
    MarkChatConversationReadUseCase? markChatConversationReadUseCase,
  }) : _bootstrapChatConversationUseCase =
           bootstrapChatConversationUseCase ??
           getIt<BootstrapChatConversationUseCase>(),
       _loadChatConversationsUseCase =
           loadChatConversationsUseCase ??
           getIt<LoadChatConversationsUseCase>(),
       _loadChatMessagesUseCase =
           loadChatMessagesUseCase ?? getIt<LoadChatMessagesUseCase>(),
       _sendChatMessageUseCase =
           sendChatMessageUseCase ?? getIt<SendChatMessageUseCase>(),
       _markChatConversationReadUseCase =
           markChatConversationReadUseCase ??
           getIt<MarkChatConversationReadUseCase>(),
       super(FeedbackChatState.initial()) {
    _openInitialConversation();
  }

  factory FeedbackChatCubit.full() {
    return FeedbackChatCubit();
  }

  factory FeedbackChatCubit.withConversation({required int conversationId}) {
    return FeedbackChatCubit(initialConversationId: conversationId);
  }

  final int? initialConversationId;
  final BootstrapChatConversationUseCase _bootstrapChatConversationUseCase;
  final LoadChatConversationsUseCase _loadChatConversationsUseCase;
  final LoadChatMessagesUseCase _loadChatMessagesUseCase;
  final SendChatMessageUseCase _sendChatMessageUseCase;
  final MarkChatConversationReadUseCase _markChatConversationReadUseCase;

  Future<void> retryOpen() async {
    await _openInitialConversation();
  }

  Future<void> _openInitialConversation() async {
    final conversationId = initialConversationId;
    if (conversationId != null) {
      await _loadConversationMessages(conversationId);
      return;
    }

    await _bootstrapChat();
  }

  Future<void> _loadConversationMessages(int conversationId) async {
    emit(
      state.copyWith(
        status: FeedbackChatStatus.loading,
        clearErrorMessage: true,
        conversationId: conversationId,
      ),
    );

    final messagesResult = await _loadChatMessagesUseCase(
      conversationId: conversationId,
    );

    await messagesResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: FeedbackChatStatus.error,
            errorMessage: failure.message,
            conversationId: conversationId,
          ),
        );
      },
      (messages) async {
        final mappedMessages = _mapMessages(messages);

        emit(
          state.copyWith(
            messages: mappedMessages,
            status: FeedbackChatStatus.loaded,
            clearErrorMessage: true,
            conversationId: conversationId,
          ),
        );

        await _markAsRead(conversationId, messages);
      },
    );
  }

  Future<void> _bootstrapChat() async {
    emit(
      state.copyWith(
        status: FeedbackChatStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final bootstrapResult = await _bootstrapChatConversationUseCase();

    await bootstrapResult.fold(
      (failure) async {
        final openedFallback = await _openFirstAvailableConversation();
        if (!openedFallback) {
          emit(
            state.copyWith(
              status: FeedbackChatStatus.error,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (conversation) async {
        if (conversation.id <= 0) {
          final openedFallback = await _openFirstAvailableConversation();
          if (!openedFallback) {
            emit(
              state.copyWith(
                status: FeedbackChatStatus.error,
                errorMessage: 'Unable to open chat right now.',
              ),
            );
          }
          return;
        }

        await _loadConversationMessages(conversation.id);
      },
    );
  }

  Future<bool> _openFirstAvailableConversation() async {
    final conversationsResult = await _loadChatConversationsUseCase(
      page: 1,
      pageSize: 1,
    );

    return await conversationsResult.fold((_) async => false, (
      conversations,
    ) async {
      if (conversations.isEmpty) {
        return false;
      }

      final conversationId = conversations.first.id;
      if (conversationId <= 0) {
        return false;
      }

      await _loadConversationMessages(conversationId);
      return state.conversationId == conversationId &&
          state.status != FeedbackChatStatus.error;
    });
  }

  Future<void> _markAsRead(
    int conversationId,
    List<ChatMessageEntity> messages,
  ) async {
    if (messages.isEmpty) {
      return;
    }

    final incomingMessages = messages.where((message) => !message.isOwn);
    if (incomingMessages.isEmpty) {
      return;
    }

    final latestIncoming = incomingMessages.reduce(_latestMessage);
    await _markChatConversationReadUseCase(
      conversationId: conversationId,
      messageId: latestIncoming.id,
    );
  }

  ChatMessageEntity _latestMessage(
    ChatMessageEntity current,
    ChatMessageEntity next,
  ) {
    final currentCreatedAt = current.createdAt;
    final nextCreatedAt = next.createdAt;

    if (currentCreatedAt != null && nextCreatedAt != null) {
      return nextCreatedAt.isAfter(currentCreatedAt) ? next : current;
    }

    if (currentCreatedAt == null && nextCreatedAt != null) {
      return next;
    }

    if (currentCreatedAt != null && nextCreatedAt == null) {
      return current;
    }

    return next.id > current.id ? next : current;
  }

  Future<bool> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    var conversationId = state.conversationId;
    if (conversationId == null) {
      await _bootstrapChat();
      conversationId = state.conversationId;
      if (conversationId == null) {
        emit(
          state.copyWith(
            status: FeedbackChatStatus.error,
            errorMessage: 'Chat is not ready yet.',
          ),
        );
        return false;
      }
    }

    emit(
      state.copyWith(
        status: FeedbackChatStatus.sending,
        clearErrorMessage: true,
      ),
    );

    final result = await _sendChatMessageUseCase(
      conversationId: conversationId,
      text: trimmed,
    );

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: FeedbackChatStatus.loaded,
            errorMessage: failure.message,
          ),
        );
        return false;
      },
      (message) {
        final nextMessages = <ChatMessage>[
          ...state.messages,
          _mapMessage(message),
        ];
        emit(
          state.copyWith(
            messages: nextMessages,
            status: FeedbackChatStatus.loaded,
            clearErrorMessage: true,
          ),
        );
        return true;
      },
    );
  }

  List<ChatMessage> _mapMessages(List<ChatMessageEntity> messages) {
    return messages.map(_mapMessage).toList()..sort((a, b) {
      final aCreatedAt = a.createdAt;
      final bCreatedAt = b.createdAt;

      if (aCreatedAt != null && bCreatedAt != null) {
        final compared = aCreatedAt.compareTo(bCreatedAt);
        if (compared != 0) {
          return compared;
        }
      } else if (aCreatedAt != null) {
        return -1;
      } else if (bCreatedAt != null) {
        return 1;
      }

      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
  }

  ChatMessage _mapMessage(ChatMessageEntity message) {
    if (message.isOwn) {
      return ChatMessage.driver(
        id: message.id,
        text: message.text,
        createdAt: message.createdAt,
      );
    } else {
      final senderName = message.sender != null
          ? '${message.sender!.firstName} ${message.sender!.lastName}'.trim()
          : 'Admin';
      return ChatMessage(
        id: message.id,
        text: message.text,
        isIncoming: true,
        senderName: senderName.isNotEmpty ? senderName : 'Admin',
        senderRole: 'admin',
        createdAt: message.createdAt,
      );
    }
  }
}
