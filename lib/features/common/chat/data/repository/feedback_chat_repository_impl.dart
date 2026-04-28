import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/data/repository/feedback_chat_repository.dart';

class FeedbackChatRepositoryImpl implements FeedbackChatRepository {
  const FeedbackChatRepositoryImpl();

  @override
  List<ChatMessage> loadPresetMessages(FeedbackChatPreset preset) {
    switch (preset) {
      case FeedbackChatPreset.full:
        return const [
          ChatMessage(
            text:
                'have any problem Ahmed ?\n'
                'you had an alert from a while',
            isIncoming: true,
          ),
          ChatMessage(
            text: 'Na, Every thing under is under control',
            isIncoming: false,
          ),
        ];
      case FeedbackChatPreset.prompt:
        return const [
          ChatMessage(
            text:
                'have any problem Ahmed ?\n'
                'you had an alert from a while',
            isIncoming: true,
          ),
        ];
    }
  }

  @override
  ChatMessage buildOutgoingMessage(String text) {
    return ChatMessage(text: text, isIncoming: false);
  }
}
