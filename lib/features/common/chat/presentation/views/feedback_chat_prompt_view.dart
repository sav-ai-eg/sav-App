import 'package:flutter/material.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_scaffold.dart';

class FeedbackChatPromptView extends StatelessWidget {
  const FeedbackChatPromptView({super.key});

  static const List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'have any problem Ahmed ?\n'
          'you had an alert from a while',
      isIncoming: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const FeedbackChatScaffold(messages: _messages);
  }
}
