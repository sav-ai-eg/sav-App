import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_sheet.dart';

class FeedbackChatScaffold extends StatefulWidget {
  final List<ChatMessage> messages;
  final ValueChanged<String> onSendText;
  final bool isLoading;
  final bool isSending;

  const FeedbackChatScaffold({
    super.key,
    required this.messages,
    required this.onSendText,
    required this.isLoading,
    required this.isSending,
  });

  @override
  State<FeedbackChatScaffold> createState() => _FeedbackChatScaffoldState();
}

class _FeedbackChatScaffoldState extends State<FeedbackChatScaffold> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    widget.onSendText(text);
    _controller.clear();
  }

  void _handleClose() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.scaffoldColor)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: AppColors.darkNavy.withValues(alpha: 0.4),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: FeedbackChatSheet(
                messages: widget.messages,
                controller: _controller,
                onSend: _handleSend,
                onClose: _handleClose,
                isLoading: widget.isLoading,
                isSending: widget.isSending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
