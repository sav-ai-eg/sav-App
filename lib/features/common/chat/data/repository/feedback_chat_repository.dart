import 'package:sav/features/common/chat/data/models/chat_message.dart';

enum FeedbackChatPreset { prompt, full }

abstract class FeedbackChatRepository {
  List<ChatMessage> loadPresetMessages(FeedbackChatPreset preset);

  ChatMessage buildOutgoingMessage(String text);
}
