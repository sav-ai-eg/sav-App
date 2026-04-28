import 'package:flutter/material.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_scaffold.dart';

class FeedbackChatView extends StatelessWidget {
  const FeedbackChatView({super.key});

  static const List<ChatMessage> _messages = [
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

  @override
  Widget build(BuildContext context) {
    return const FeedbackChatScaffold(messages: _messages);
  }
}
