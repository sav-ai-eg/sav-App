import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/data/repository/feedback_chat_repository.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/usecases/bootstrap_chat_conversation_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/load_chat_messages_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/mark_chat_conversation_read_use_case.dart';
import 'package:sav/features/common/chat/domain/usecases/send_chat_message_use_case.dart';
import 'package:sav/features/common/chat/presentation/cubit/feedback_chat_state.dart';

class FeedbackChatCubit extends Cubit<FeedbackChatState> {
  FeedbackChatCubit._({required FeedbackChatPreset preset})
      : _preset = preset,
        _bootstrapChatConversationUseCase =
            getIt<BootstrapChatConversationUseCase>(),
        _loadChatMessagesUseCase = getIt<LoadChatMessagesUseCase>(),
        _sendChatMessageUseCase = getIt<SendChatMessageUseCase>(),
        _markChatConversationReadUseCase =
            getIt<MarkChatConversationReadUseCase>(),
        super(
          FeedbackChatState.initial(
            messages: preset == FeedbackChatPreset.prompt
                ? const [
                    ChatMessage(
                      text:
                          'have any problem Ahmed ?\nyou had an alert from a while',
                      isIncoming: true,
                    ),
                  ]
                : const [],
          ),
        ) {
    _bootstrapChat();
  }

  factory FeedbackChatCubit.full() {
    return FeedbackChatCubit._(preset: FeedbackChatPreset.full);
  }

  factory FeedbackChatCubit.prompt() {
    return FeedbackChatCubit._(preset: FeedbackChatPreset.prompt);
  }

  final FeedbackChatPreset _preset;
  final BootstrapChatConversationUseCase _bootstrapChatConversationUseCase;
  final LoadChatMessagesUseCase _loadChatMessagesUseCase;
  final SendChatMessageUseCase _sendChatMessageUseCase;
  final MarkChatConversationReadUseCase _markChatConversationReadUseCase;

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
        emit(
          state.copyWith(
            status: FeedbackChatStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (conversation) async {
        final messagesResult = await _loadChatMessagesUseCase(
          conversationId: conversation.id,
        );

        await messagesResult.fold(
          (failure) async {
            emit(
              state.copyWith(
                status: FeedbackChatStatus.error,
                errorMessage: failure.message,
                conversationId: conversation.id,
              ),
            );
          },
          (messages) async {
            final mappedMessages = _mapMessages(messages);
            final nextMessages = mappedMessages.isEmpty &&
                    _preset == FeedbackChatPreset.prompt
                ? state.messages
                : mappedMessages;

            emit(
              state.copyWith(
                messages: nextMessages,
                status: FeedbackChatStatus.loaded,
                clearErrorMessage: true,
                conversationId: conversation.id,
              ),
            );

            await _markAsRead(conversation.id, messages);
          },
        );
      },
    );
  }

  Future<void> _markAsRead(
    int conversationId,
    List<ChatMessageEntity> messages,
  ) async {
    if (messages.isEmpty) {
      return;
    }

    final incomingMessages =
        messages.where((message) => !message.isOwn).toList();
    if (incomingMessages.isEmpty) {
      return;
    }

    final latestIncoming = incomingMessages.last;
    await _markChatConversationReadUseCase(
      conversationId: conversationId,
      messageId: latestIncoming.id,
    );
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final conversationId = state.conversationId;
    if (conversationId == null) {
      emit(
        state.copyWith(
          status: FeedbackChatStatus.error,
          errorMessage: 'Chat is not ready yet.',
        ),
      );
      return;
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

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: FeedbackChatStatus.loaded,
            errorMessage: failure.message,
          ),
        );
      },
      (message) {
        final nextMessages = <ChatMessage>[...state.messages, _mapMessage(message)];
        emit(
          state.copyWith(
            messages: nextMessages,
            status: FeedbackChatStatus.loaded,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  List<ChatMessage> _mapMessages(List<ChatMessageEntity> messages) {
    return messages.map(_mapMessage).toList();
  }

  ChatMessage _mapMessage(ChatMessageEntity message) {
    return ChatMessage(
      text: message.text,
      isIncoming: !message.isOwn,
    );
  }
}
